#!/usr/bin/env ruby

if ARGV.size < 2
  STDERR.puts "Usage: $0 <schema_json_file> <graphql-ruby-git_dir> [output_dir || ./graphql/]"
  exit 1
end

require 'json'
require 'logger'
require 'fileutils'
require 'active_support/core_ext/string/inflections'

# Positions for text insertion. Empty values/places are squashed.
PREAMBLE = 5
HEADER = 10
INTERFACES = 12
POSSIBLE_TYPES = 15
INCLUDES = 20
DEF_METHODS = 25
FIELDS = 30
POSTAMBLE = 50

$overwrite = true

$log= Logger.new STDOUT
$log.level = Logger::DEBUG
$log.formatter = proc do |severity, datetime, progname, msg| "#{severity.to_s}: #{msg}\n" end

# Schema contains:
# 1) Names of query, mutation, and subscription entry point types
# 2) Types and directives (of which types include almost everything -- query types, mutation types, input types, and response/payload types)
#
# Therefore, obviously types are by far the largest group.
# In Solidus GraphQL API, we split out 3 sub-types into their own directories: interfaces, input objects, and payloads.
# And even though they are all types, we give them different prefix: Interfaces::X, Inputs::X, and Payloads::X.

# Load schema Hash into $schema
schema_text= File.read ARGV.shift
schema_text.gsub! /hopify\.com/, 'olidus.io'
schema_text.gsub! /hopify/, 'olidus'
schema_text.gsub! /HOPIFY/, 'OLIDUS'
schema = JSON.parse schema_text
$schema = schema['data']['__schema']
$schema_type_map = {}

# Define where is the Git checkout of rmosolgo's graphql-ruby
$graphql_ruby_dir= ARGV.shift

# Define directory where generated files will be output, defaults to ./graphql
$out_dir= ARGV.shift || './solidus_graphql_api/'

puts "Output dir is #{$out_dir}.
Schema files will be overwritten.
Implementation files will#{ $overwrite ? '' : ' not'} be overwritten.
Spec files will#{ $overwrite ? '' : ' not'} be overwritten.
"

# Names of query/mutation/subscription entry points
$query= $mutation= $subscription= nil

# Hash containing a 'catalog' of a bunch of stuff for looking up during execution.
$catalog = {

  # Mapping of types in schema to our types.
  #
  # In general, almost everything in GraphQL is a type. However, as mentioned we
  # sub-divide types into 1) interfaces, 2) inputs, 3) payloads, and 4) all other types.
  # We also set class name to be <type>::<name>, such as Interfaces::Node.
  # Because of that, when the code starts, it needs to do a first pass through all types
  # to figure out what sub-type/full name in Solidus GraphQL they map to.
  # E.g.:
  # 'AppliedDiscount' => 'Interfaces::AppliedDiscount'
  #
  # Also, this list is used to map built-in types to the same value, since they don't need to
  # get any custom prefix.
  # (The list of these built-in types in populated automatically from data found in graphql-ruby.)
  #
  # Also, this list can be used to remap any type to any other/different name in Solidus' GraphQL, if needed.
  type_names: {
    'ID' => 'ID'
  },

  # Manually-maintained list of GraphQL -> Spree factory mappings, so that the templates
  # could be even more ready-made.
  factories: {
    'shop' => 'store'
  },

  # List of original names and output files they map to. Both for schema/autogenerated files
  # and for user-modifiable files. If file is not inserted here, it is not output.
  # Format is:  new_name => part_of_filename
  # E.g. Schema::Types::Shop => 'schema/types/shop'
  schema_outputs: {
  },
  outputs: {
  },
  spec_outputs: {
  },

  # Contents of output files (schema/autogenerated files, and user-implementable files)
  # TODO Replace with {}
  schema_contents: Hash.new([]),
  contents: Hash.new([]),
  spec_contents: Hash.new([]),

  # Dependencies -- used to detect/solve circular dependencies
  # Format is: ClassAString => ClassBString
  # E.g.   Checkout => Customer, Customer => Checkout
  depends: {},

  # List of built-in types.
  # Format: TypeNameString => true
  builtins: {},

  # This lists any problems found during parsing which may affect the
  # success of conversion of JSON schema to .rb files. Currently used/populated
  # but without any practical effect.
  problems: {
    directives: {},
  },

  # TODO what about accessRestricted etc.

  base_type: {},

  # TODO remove when no longer referenced from anywhere
  snippets: {}
}

# List types which aren't database models here!
$catalog[:base_type]['Types::Domain'] = 'Types::BaseObjectNoId'


# This is the entry point into the program. It invokes all necessary functions,
# writes results to disk and exits.
def run
  $schema.each do |k, v|
    case k
    when 'queryType'
      $query= v['name'] if v
    when 'mutationType'
      $mutation= v['name'] if v
    when 'subscriptionType'
      $subscription= v['name'] if v
    when 'directives'
      parse_directives v
    when 'types'
      parse_types_1 v
    else
      STDERR.puts "Unrecognized schema element '#{k}'. This probably means that the parser file '#{$0}' needs to be updated to support it."
      exit 1
    end
  end

  # Now we are certain that $query/$mutation/$subscription are filled in.
  # They contain the names of types that serve as entry points into the respective parts of schema.
  if !$query; $log.fatal "Did not find name of query entry in JSON schema; exiting."; exit 1 end
  if !$mutation; $log.fatal "Did not find name of mutation entry in JSON schema; exiting."; exit 1 end
  if $subscription
    $log.error "Found a 'subscription' entry point. Previously this wasn't present, so an update to '#{$0}' is needed to support it. For implementation, see existing implementations for queries and mutations; exiting."
    exit 1
  end

  # Let's now parse all types. This is the pass 2 of type parsing.
  parse_types_2 $schema['types']

  # And now we can output all files to disk.
  output_files()

  #pp $catalog
  puts 'Done.'

  exit 0
end

#####################################################################
# Helper methods below

def parse_directives(v)
  $log.info "Found %s directives." % [v.size]
  v.each do |d|
    next if d['isDeprecated']

    n= d['name']
    if File.exists? "#{$graphql_ruby_dir}/lib/graphql/directive/#{n}_directive.rb"
      $log.debug "Skipping parsing of directive '#{n}' which is a built-in supported by graphql-ruby."
      next
    end
    #$log.warn "Directive '#{n}' found in schema, but does not appear supported in graphql-ruby, and graphql-ruby currently also does not support defining custom directives. If this directive will appear used anywhere, then this warning will be promoted to an error; continuing."
    $catalog[:problems][:directives][n] = true
  end
end

def check_skip(t)
  # This method is only called for toplevel types. And in them, we are not
  # interested in Connection/Edge types.
  return true if (t['name']=~ /(?:Connection|Edge)$/) || (t['name']=~ /^__/) || ($catalog[:builtins][t['name']]) || t['isDeprecated']
  false
end

# First pass of parsing types
def parse_types_1(v)
  #if $catalog[:builtins].keys.size== 0
  # STDERR.puts 'parse_directives() must be called before parse_types_1(); exiting.'
  # exit 1
  #end

  builtins = Dir["#{$graphql_ruby_dir}/lib/graphql/types/*.rb"]
  builtins.each do |b|
    bc = File.read b
    bc =~ /class\s+(\w+)\s+</
    next unless $1
    $log.debug "Registering type '#{$1}' as built-in type supported by graphql-ruby."
    $catalog[:type_names][$1] = "::GraphQL::Types::#{$1}"
    $catalog[:builtins][$1] = true
    next
  end

  # Do just some basic things here, which need to be done in 1st pass.
  # The types are parsed "for real" later, in pass 2. This 1st pass is here
  # to solve a chicken-or-egg problem.
  v.each do |t|
    $schema_type_map[t['name']] = t
    next if check_skip(t)

    name = t['name']

    # Do not overwrite (just skip) built-in types
    next if $catalog[:type_names][name]

    if $catalog[:type_names][name]
      $log.fatal "Duplicate type name #{name}. This represents an unhandled case in the script and should be looked into manually; exiting."
      exit 1
    end

    new_name= old_to_new_name(t)
    $catalog[:type_names][name] = new_name

    $catalog[:base_type][new_name] ||=
      if new_name=~ /^Payloads::/
        'Payloads::BasePayload'
      else
        case t['kind']
        when 'ENUM'
          'Types::BaseEnum'
        when 'SCALAR'
          'Types::BaseScalar'
        when 'INPUT_OBJECT'
          'Inputs::BaseInput'
        when 'INTERFACE'
          'Interfaces::BaseInterface'
        when 'UNION'
          'Types::BaseUnion'
        else
          'Types::BaseObject'
        end
      end

    # Even though contents will be filled in later, register files for output to disk here.
    of= new_name.dup
    of.gsub! '::', '/'
    # This is the schema-related part (should be non-modifiable by user)
    $catalog[:schema_outputs][new_name]= of.underscore

    if new_name=~ /^(?:Types|Interfaces)::/
      # This is the implementation-related part (user should add implementation code)
      $catalog[:outputs][new_name]= of.underscore

      # Implementation test (user should also review/modify test)
      $catalog[:spec_outputs][new_name]= of.underscore
    end
  end
end

def parse_types_2(v)
  $log.info "Found total %s types." % [v.size]

  v.each do |type|
    next if check_skip(type)

    name= type['name']
    new_name = $catalog[:type_names][name]
    unless name and new_name
      STDERR.puts "parse_types_2() did not find a mapping for #{name}; exiting."
      exit 1
    end

    $catalog[:schema_contents][new_name]= []
    $catalog[:schema_contents][new_name][PREAMBLE]||= []
    $catalog[:schema_contents][new_name][HEADER]||= []
    $catalog[:schema_contents][new_name][INTERFACES]||= []
    $catalog[:schema_contents][new_name][POSSIBLE_TYPES]||= []
    $catalog[:schema_contents][new_name][INCLUDES]||= []
    $catalog[:schema_contents][new_name][DEF_METHODS]||= []
    $catalog[:schema_contents][new_name][FIELDS]||= []
    $catalog[:schema_contents][new_name][POSTAMBLE]||= []

    $catalog[:contents][new_name]= []
    $catalog[:contents][new_name][PREAMBLE]||= []
    $catalog[:contents][new_name][HEADER]||= []
    $catalog[:contents][new_name][INTERFACES]||= []
    $catalog[:contents][new_name][POSSIBLE_TYPES]||= []
    $catalog[:contents][new_name][INCLUDES]||= []
    $catalog[:contents][new_name][DEF_METHODS]||= []
    $catalog[:contents][new_name][FIELDS]||= []
    $catalog[:contents][new_name][POSTAMBLE]||= []

    $catalog[:spec_contents][new_name]= []
    $catalog[:spec_contents][new_name][PREAMBLE]||= []
    $catalog[:spec_contents][new_name][HEADER]||= []
    $catalog[:spec_contents][new_name][INTERFACES]||= []
    $catalog[:spec_contents][new_name][POSSIBLE_TYPES]||= []
    $catalog[:spec_contents][new_name][INCLUDES]||= []
    $catalog[:spec_contents][new_name][DEF_METHODS]||= []
    $catalog[:spec_contents][new_name][FIELDS]||= []
    $catalog[:spec_contents][new_name][POSTAMBLE]||= []

    helper = make_helper_for type

    prepare_headers_for type, helper
    parse_interfaces_for type, helper
    parse_possible_types_for type, helper
    parse_fields_for type, helper
    parse_enum_values_for(type, helper)
    parse_args_for(type, helper, nil, 'inputFields')
  end
end

def output_files
  name= 'Schema'
  $catalog[:schema_contents][name] = %Q{class Spree::GraphQL::Schema::Schema < GraphQL::Schema
  query ::Spree::GraphQL::Schema::Types::#{$query}
  mutation ::Spree::GraphQL::Schema::Types::#{$mutation}

  def self.id_from_object(object, type_definition, query_context)
    ::GraphQL::Schema::UniqueWithinType.encode(object.class.name, object.id)
  end

  def self.object_from_id(id, query_context)
    class_name, item_id = ::GraphQL::Schema::UniqueWithinType.decode(id)
    ::Object.const_get(class_name).find(item_id)
  end
end}
  $catalog[:schema_outputs][name] = 'schema'

  name= 'Types::BaseObject'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Types::BaseObject < GraphQL::Schema::Object
  global_id_field :id
  include ::Spree::GraphQL::Types::BaseObject
end"
  $catalog[:schema_outputs][name]= 'types/base_object'
  # User part:
  $catalog[:contents][name]= "module Spree::GraphQL::Types::BaseObject\nend"
  $catalog[:outputs][name]= 'types/base_object'
  #$catalog[:spec_outputs][name]= 'types/base_object'

  name= 'Types::BaseObjectNoId'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Types::BaseObjectNoId < GraphQL::Schema::Object
  include ::Spree::GraphQL::Types::BaseObject
end"
  $catalog[:schema_outputs][name]= 'types/base_object_no_id'
  # (User part is the same as for BaseObject)

  name= 'Types::BaseEnum'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Types::BaseEnum < GraphQL::Schema::Enum
  include ::Spree::GraphQL::Types::BaseEnum
end"
  $catalog[:schema_outputs][name]= 'types/base_enum'
  # User part:
  $catalog[:contents][name]= "module Spree::GraphQL::Types::BaseEnum\nend"
  $catalog[:outputs][name]= 'types/base_enum'
  #$catalog[:spec_outputs][name]= 'types/base_enum'

  name= 'Types::BaseScalar'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Types::BaseScalar < GraphQL::Schema::Scalar
  include ::Spree::GraphQL::Types::BaseScalar
end"
  $catalog[:schema_outputs][name]= 'types/base_scalar'
  # User part:
  $catalog[:contents][name]= "module Spree::GraphQL::Types::BaseScalar\nend"
  $catalog[:outputs][name]= 'types/base_scalar'
  #$catalog[:spec_outputs][name]= 'types/base_scalar'

  name= 'Interfaces::BaseInterface'
  $catalog[:schema_contents][name]= "module Spree::GraphQL::Schema::Interfaces::BaseInterface
  include ::GraphQL::Schema::Interface
end"
  $catalog[:schema_outputs][name]= 'interfaces/base_interface'
  # User part:
  $catalog[:contents][name]= "module Spree::GraphQL::Interfaces::BaseInterface\nend"
  $catalog[:outputs][name]= 'interfaces/base_interface'
  #$catalog[:spec_outputs][name]= 'interfaces/base_interface'

  name= 'Types::BaseUnion'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Types::BaseUnion < GraphQL::Schema::Union
  include ::Spree::GraphQL::Types::BaseUnion
end"
  $catalog[:schema_outputs][name]= 'types/base_union'
  # User part:
  $catalog[:contents][name]= "module Spree::GraphQL::Types::BaseUnion\nend"
  $catalog[:outputs][name]= 'types/base_union'
  #$catalog[:spec_outputs][name]= 'types/base_union'

  name= 'Inputs::BaseInput'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Inputs::BaseInput < GraphQL::Schema::InputObject\nend"
  $catalog[:schema_outputs][name]= 'inputs/base_input'
  # User part:
  #$catalog[:contents][name]= "module Spree::GraphQL::Inputs::BaseInput\nend"
  #$catalog[:outputs][name]= 'inputs/base_input'
  #$catalog[:spec_outputs][name]= 'inputs/base_input'

  name= 'Payloads::BasePayload'
  $catalog[:schema_contents][name]= "class Spree::GraphQL::Schema::Payloads::BasePayload < GraphQL::Schema::Object\nend"
  $catalog[:schema_outputs][name]= 'payloads/base_payload'
  # User part:
  #$catalog[:contents][name]= "module Spree::GraphQL::Payloads::BasePayload\nend"
  #$catalog[:outputs][name]= 'payloads/base_payload'
  #$catalog[:spec_outputs][name]= 'payloads/base_payload'

  # Output total file list of files that can be 'require'd (so, excluding specs):
  outfile = "#{$out_dir}/lib/solidus_graphql_api/graphql/file_list.rb"
  FileUtils.mkdir_p File.dirname outfile
  File.open(outfile, 'w') { |f| f.write "# This file lists all the files that were auto-generated.
# It cannot be used as-is because the order of includes
# does not represent actual dependencies between files.
#
# Use it only for convenience to easily spot additions
# or removals in the list of files and to then update file
# all.rb manually, taking the necessary order of includes
# into account.\n" +
    $catalog[:outputs].values.map{|f| %Q{require_relative "./#{f}"}}.join("\n") + "\n\n" +
    $catalog[:schema_outputs].values.map{|f| %Q{require_relative "./schema/#{f}"}}.join("\n") + "\n"
  }

  # Output schema parts:
  $catalog[:schema_outputs].each do |name, file|
    content = $catalog[:schema_contents][name]
    content = (Array === content) ? content.flatten.compact.join("\n") : content
    outfile = "#{$out_dir}/lib/solidus_graphql_api/graphql/schema/#{file}.rb"
    FileUtils.mkdir_p File.dirname outfile
    File.open(outfile, 'w') { |f| f.write content }
  end

  # Output user parts:
  $catalog[:outputs].each do |name, file|
    content = $catalog[:contents][name]
    content = (Array === content) ? content.flatten.compact.join("\n") : content
    outfile = "#{$out_dir}/lib/solidus_graphql_api/graphql/#{file}.rb"
    FileUtils.mkdir_p File.dirname outfile
    if !File.exists?(outfile) or $overwrite
      File.open(outfile, 'w') { |f| f.write content}
    else
      $log.debug "Not overwriting #{outfile}"
    end
  end

  # Output specs:
  $catalog[:spec_outputs].each do |name, file|
    content = $catalog[:spec_contents][name]
    content = (Array === content) ? content.flatten.compact.join("\n") : content
    outfile = "#{$out_dir}/spec/graphql/#{file}_spec.rb"
    FileUtils.mkdir_p File.dirname outfile
    if !File.exists?(outfile) or $overwrite
      File.open(outfile, 'w') { |f| f.write content}
    else
      $log.debug "Not overwriting #{outfile}"
    end
  end
end

def make_helper_for(type)
  new_name = $catalog[:type_names][type['name']]

  helper= {
    new_name: new_name,
    interfaces: [],
    possible_types: [],
    root_query: ( type['name'] == $mutation ? 'mutation' : 'query'),
  }

  helper
end

def prepare_headers_for(type, helper)
  new_name= helper[:new_name]
  desc= type['description'] ? "%q{#{type['description']}}" : 'nil'

  if $catalog[:base_type][new_name]== 'Interfaces::BaseInterface'

    $catalog[:schema_contents][new_name][HEADER].push %Q{module Spree::GraphQL::Schema::#{new_name}
  include ::Spree::GraphQL::Schema::#{$catalog[:base_type][new_name]}
  graphql_name '#{type['name']}'
  description #{desc}}
    $catalog[:schema_contents][new_name][INCLUDES].push indent 1, "include ::Spree::GraphQL::#{new_name}"
    $catalog[:schema_contents][new_name][DEF_METHODS].push indent 1, "definition_methods do\nend"

  else
    $catalog[:schema_contents][new_name][HEADER].push %Q{class Spree::GraphQL::Schema::#{new_name} < Spree::GraphQL::Schema::#{$catalog[:base_type][new_name]}
  graphql_name '#{type['name']}'
  description #{desc}}
    if new_name=~ /^(?:Types|Interfaces)::/
      $catalog[:schema_contents][new_name][INCLUDES].push indent 1, "include ::Spree::GraphQL::#{new_name}"
    end
  end

  $catalog[:contents][new_name][HEADER].push %Q{# frozen_string_literal: true
module Spree::GraphQL::#{new_name}}

  $catalog[:spec_contents][new_name][HEADER].push %Q{# frozen_string_literal: true
require 'spec_helper'

module Spree::GraphQL
  describe '#{new_name}' do
    let!(:#{type['name'].underscore}) { create(:#{$catalog[:factories][type['name'].underscore] || type['name'].underscore}) }
    let!(:ctx) { { current_store: current_store } }
    let!(:variables) { }
}
end

def parse_interfaces_for(type, helper)
  new_name = helper[:new_name]

  if type['interfaces']
    type['interfaces'].each do |i|
      if i['ofType'] or i['kind']!= 'INTERFACE'
        $log.error "Found type #{type['name']} which implements interface #{i['name']}, but can't parse that interface because of its 'kind' and/or 'ofType' fields. This needs to be looked into and improved in the generator script; exiting."
        exit 1
      end
      $catalog[:schema_contents][new_name][INTERFACES].push indent 1, "implements ::Spree::GraphQL::Schema::#{$catalog[:type_names][i['name']]}"
      $catalog[:contents][new_name][INTERFACES].push indent 1, "include ::Spree::GraphQL::#{$catalog[:type_names][i['name']]}"
    end
  end
end

def parse_possible_types_for(type, helper)
  new_name = helper[:new_name]

  types= []

  if type['possibleTypes'] and type['kind']== 'UNION'
    type['possibleTypes'].each do |i|
      if i['ofType'] or i['kind']!= 'OBJECT'
        $log.error "Found type #{type['name']} which has possible type #{i['name']}, but can't parse that type because of its 'kind' and/or 'ofType' fields. This needs to be looked into and improved in the generator script; exiting."
        exit 1
      end
      unless $catalog[:type_names][i['name']]
        $log.error "Missing name mapping for possible type #{i['name']}. This needs to be looked into/fixed manually in the generator script; exiting."
      end
      types.push $catalog[:type_names][i['name']]
    end
  end

  if types.size> 0
    string= types.map{|t| "class Spree::GraphQL::Schema::#{t} < Spree::GraphQL::Schema::#{$catalog[:base_type][t]}; end"}.join("\n")
    $catalog[:schema_contents][new_name][PREAMBLE].unshift string

    string= indent 1, "possible_types \\\n"+ types.map{|t| "  ::Spree::GraphQL::Schema::#{t}"}.join(",\n")
    $catalog[:schema_contents][new_name][POSSIBLE_TYPES].unshift string
  end
end

def parse_enum_values_for(type, helper)
  new_name = helper[:new_name]
  # Parse enum values
  if type['enumValues']
    type['enumValues'].each do |v|
      next if v['isDeprecated']
      description= v['description'] ? "%q{#{v['description']}}" : 'nil'
      $catalog[:schema_contents][new_name][FIELDS].push indent(1, %Q{value '#{v['name']}', }) + description
    end
  end
  
  $catalog[:schema_contents][new_name][POSTAMBLE].push 'end'
  $catalog[:contents][new_name][POSTAMBLE].push 'end'
  $catalog[:spec_contents][new_name][POSTAMBLE].push "  end\nend"
end

def parse_fields_for(type, helper)
  new_name = helper[:new_name]

  if type['fields']
    type['fields'].each do |field|
      next if field['isDeprecated']

      base_type, return_type, short, is_connection, is_array= type_of_field(field, type)
      description= field['description'] ? "%q{#{field['description']}}" : 'nil'

      $catalog[:schema_contents][new_name][FIELDS].push indent(1, %Q{field :#{field['name'].underscore}, #{return_type} do
  description }) + description

      method_args= parse_args_for(type, helper, field, 'args', is_connection)
      
      $catalog[:schema_contents][new_name][FIELDS].push indent 1, 'end'

      args_with_desc= method_args.map{|a| "# @param #{a[0]} [#{a[1]}]#{a[3] ? ' ('+a[3]+')' : ''}#{ a[2] ? ' ' + oneline(a[2]) : ''}"}.join("\n")
      args= '(' + method_args.map{|a| a[0]+ ':'}.join(', ')+ ')'
      args_for_spec= method_args.map{|a| "# @param #{a[0]} [#{a[1]}]#{a[3] ? ' ('+a[3]+')' : ''}"}.join("\n")
      #helper['class']= type['name'].underscore

      $catalog[:contents][new_name][FIELDS].push indent 1, %Q{\n# #{field['name']}#{ field['description'] ? (': '+ oneline(field['description'])) : ''}#{args_with_desc.size>0 ? "\n" + args_with_desc : ''}
# @return [#{shorten return_type}]
def #{field['name'].underscore}#{args}
  raise ::Spree::GraphQL::NotImplementedError.new
end
}

      content= type_to_hash(base_type, return_type, short, is_connection, is_array)
      if is_connection and is_array
        raise Exception.new "Didn't expect it"
      end
      if is_connection
        content = wrap_to_connection content
      #elsif is_array
      #  content = [content]
      end
      fields_hash_string = indent 5, hash_to_graphql_query([ field['name'], field_args_to_hash(field)] => content)

      # TODO complete the print of input query and expected response

      query_type = type['name'] == $mutation ? 'mutation' : 'query'
      $catalog[:spec_contents][new_name][FIELDS].push indent 2, %Q{# #{field['name']}#{ field['description'] ? (': '+ oneline(field['description'])) : ''}#{(args_for_spec).size>0 ? "\n" + args_for_spec : ''}
# @return [#{shorten return_type}]
describe '#{field['name']}' do
  let!(:query) {
    %q{
      #{query_type} {
        #{type['name'].camelize(:lower)} {#{fields_hash_string}
        }
      }
    }
  }
  let!(:result) { result_body(type, helper) }
  #it 'succeeds' do
  #  execute
  #  expect(response_hash).to eq(result_hash)
  #end
end
}
      end # type['fields'].each
    end # endif type['fields']
end

def parse_args_for(type, helper, field, key, is_connection = false)
  new_name = helper[:new_name]
  method_args= []

  thing = case key
    when 'args'
      field
    when 'inputFields'
      type
    else
      raise Exception.new 'Should not happen'
  end
  args = thing[key]
  if args
    args.each do |arg|
      next if arg['isDeprecated']
      if is_connection
        next if %w/first last before after pageInfo/.include? arg['name']
      end

      chain = []
      if ft = arg['type']
        while ft
          chain.unshift ft
          ft = ft['ofType']
        end
      end
      string= ''
      arg_type= nil
      default_value_string= ''
      chain.each do |t2|
        if t2['kind'] == 'NON_NULL' and !t2['name']; string.sub! /false$/, 'true'
        elsif t2['kind'] == 'LIST' and !t2['name']; string = "[#{string}], required: false"
        else
          suffix = ''
          arg_type= t2['name']
          if arg_type.sub! /Connection$/, ''
            suffix = '.connection_type'
          end
          method_args.push [arg['name'].underscore]
          arg_type = $catalog[:type_names][arg_type]
          unless arg_type=~ /^::/
            arg_type= '::Spree::GraphQL::Schema::'+ arg_type
          end
          string = "#{arg_type + suffix}, required: false"
        end
      end

      # graphql-ruby has two specifics:
      # 1) Types have null: true/false, while arguments have required: true/false
      # 2) Additionally, in lists of type, the 'null: false' is default and not allowed to be specified
      # So the following is needed to comply with that:
      string.gsub! ', required: true]', ']' # 'null: false]'
      string.gsub! ', required: false]', ']'

      # Derive short description of type (e.g. "[String!]!")
      method_args[-1].push shorten(string)
      method_args[-1].push arg['description']

      arg_type= string
      # Determine if default value needs to be set
      unless string=~ /required: true/
        default_value= 'nil'
      end
      if arg['defaultValue']
        val=
          (if arg['defaultValue']=~ /^(?:\d+(?:\.\d+)?|false|true)$/
            arg['defaultValue']
          else
            %q{'}+ arg['defaultValue']+ %q{'}
          end)
        default_value_string = " default_value: #{val},"
        method_args[-1].push val
      end
      description= arg['description'] ? "%q{#{arg['description']}}" : 'nil'

      ind = 1
      if field
        ind = 2
      end
      $catalog[:schema_contents][new_name][FIELDS].push indent(ind, "argument :#{arg['name'].underscore}, #{arg_type},#{default_value_string} description: ") + description
    end
  end # if field['args']
  method_args
end



################################################################################

def hash_to_method_args(hash)
  unless Hash=== hash
    raise Exception.new "Not expected type #{hash.class}--#{hash}"
  end
  ret= []
  hash.each{ |k,v|
    unless k.is_a? Array
      k_string = k
    else
      k_string = if k[1]
        "#{k[0]}(#{hash_to_method_args k[1]})"
      else
        k[0]
      end
    end

    value= case v
    when Hash
      pre= '{'
      post= '}'
      if args= hash_to_method_args(v)
        if args.lines.size> 1
          pre= "{\n"
          args= indent 1, args
          post= "\n}"
        end
      end
      pre + args + post
    else
      v
    end
    ret.push "#{k_string}: #{value}"
  }
  if ret.size <2
    ret.join(", ")
  else
    ret.join(",\n")
  end
end

def field_args_to_hash(field)
  ret= {}

  if field['args']
    field['args'].each {|a|
      base, return_type, short, is_connection, is_array = type_of_field(a)
      if is_connection
        raise Exception.new "Didn't expect connection here"
      end
      name= a['name']
      value=
        if base== 'Int' or base== 'Float'
          base
        elsif base== 'Boolean'
          a['defaultValue']
        elsif base== 'String' or a['kind']== 'SCALAR'
          '""'
        elsif a['kind']== 'ENUM'
          a['enumValues'].map{|v| v['name']}.join(' | ')
        elsif a['kind']== 'UNION'
          a['possibleTypes'].map{|v| v['name']}.join(' | ')
        else
          # What remains? OBJs and INPUT OBJs?
          #raise Exception.new "Not seen: #{base} (#{p a})"
          bt, _, _, is_connection, is_array = type_of_field(a)
          if is_connection
            raise Exception.new "Didn't expect connection here"
          end
          type_to_hash($schema_type_map[bt], return_type, short, is_connection, is_array)
        end
      ret[name]= value
    }
  end

  ret.size> 0 ? ret : nil #.map{|k,v| "#{k}: #{v}"}.join(', ') : nil
end



################################################################################
# Helper methods

# type_of_field(field) - returns [base, string, short(string), is_connection]
# type_to_hash(type) - expands type into nested hash of inputs
# hash_to_graphql_query - converts hash from type_to_hash to graphql query syntax
# field_args_to_hash - expands field args into hash
# hash_to_method_args - hash returned from above to string
# shorten - shortens ruby type definition string into graphql notation (e.g. '[X], null: false' -> '[X]!')
# old_to_new_name - maps original GraphQL name to our class name
# indent - indents by given level
# oneline - converts whatever to oneliner

def type_of_field(field, type= nil)
  new_name = nil
  if type
    new_name = $catalog[:type_names][type['name']]
    unless new_name
      raise Exception.new "Unknown/unseen type #{type['name']}?"
    end
  end

  ret_type= nil
  chain = []
  if ft = field['type']
    while ft
      chain.unshift ft
      ft = ft['ofType']
    end
  end
  string = ''
  is_connection = false
  is_array = false
  chain.each do |f2|
    if f2['kind'] == 'NON_NULL' and !f2['name']; string.sub! /true$/, 'false'
    elsif f2['kind'] == 'LIST' and !f2['name']; is_array= true; string = "[#{string}], null: true"
    else
      suffix= ''
      ret_name= f2['name']
      if ret_name.sub! /Connection$/, ''
        suffix = '.connection_type'
        is_connection = true
      end
      ret_name= $catalog[:type_names][ret_name]
      ret_type= f2['name']
      unless ret_name
        STDERR.puts "No name map for #{f2['name']}. Check that you are properly looking up entries in $catalog[:type_names] Hash; exiting."
        exit 1
      end

      if type
        $catalog[:depends][new_name] ||= {}
        $catalog[:depends][new_name][ret_name] = true
        if (new_name != ret_name) && ($catalog[:depends][ret_name]) && ($catalog[:depends][ret_name][new_name])
          $log.info "Class #{new_name} depends on #{ret_name} and vice-versa. Will handle accordingly."
          preamble_text= "class Spree::GraphQL::Schema::#{ret_name} < Spree::GraphQL::Schema::#{$catalog[:base_type][ret_name]}; end"
          $catalog[:schema_contents][new_name][PREAMBLE].unshift(preamble_text) unless $catalog[:schema_contents][new_name][PREAMBLE].include?(preamble_text)
        end
      end

      unless ret_name=~ /^::/
        ret_name= '::Spree::GraphQL::Schema::'+ ret_name
      end

      string = "#{ret_name+ suffix}, null: true"
    end
  end # chain.each do |f2|

  # graphql-ruby has two specifics:
  # 1) Types have null: true/false
  # 2) Additionally, in lists of type, the 'null: false' is default and not allowed to be specified
  # So the following is needed to comply with that:
  string.gsub! ', null: false]', ']'

  # Return is:
  # 1. Base GraphQL type (can be then looked up by that name in $schema_type_map) (e.g. Article)
  # 2. String suitable for field definition in GraphQL-Ruby syntax (e.g. [Type], null: false)
  # 3. String suitable for field definition in GraphQL (e.g. [Type!]!)
  # 4. Boolean whether that field returns a connection
  # 5. Boolean whether the field is an array
  [ ret_type, string, shorten(string), is_connection, is_array ]
end

$resolving= {}
def type_to_hash(type, ruby_string = nil, short_string = nil, is_connection = false, is_array = false)
  t= (String=== type) ? $schema_type_map[type] : type

  # Prevent loops
  if $resolving[t['name']]
    return %Q{"#{t['name']}..."}
  end

  $resolving[t['name']]= true

  short_string ||= t['name']

  raise Exception.new "Not expected" unless t

  if t['fields'] and t['inputFields']
    raise Exception.new "Didn't expect that type #{t['name']} will have both fields and inputFields"
  end

  retval=
    case t['kind']
    when 'SCALAR'
      is_array ? %Q{["#{t['name']}"]} : %Q{"#{t['name']}"}
    when 'UNION'
      %Q{#{t['possibleTypes'].map{|t| t['name']}.join ' | '}}
    when 'ENUM'
      %Q{"#{t['enumValues'].map{|v| v['name']}.join ' | '}"}
    when 'OBJECT', 'INPUT_OBJECT', 'INTERFACE'
      ret= {}
      fields= t['fields'] || t['inputFields']
      fields.each do |f|
        base, _, _, is_connection= type_of_field(f)
        content= type_to_hash(base)
        if is_connection
          content = wrap_to_connection content
        end
        ret.merge!( [f['name'], field_args_to_hash(f)] => content )
      end
      ret
    else
      raise Exception.new "Unhandled kind #{t['kind']}"
    end

  $resolving.delete t['name']
  retval
end

$level= 0
def hash_to_graphql_query(hash)
  string= ''
  hash.each do |k,v|
    k_string = if k[1]
      pre= '('
      post= ')'
      if args = hash_to_method_args(k[1])
        if args.lines.size > 1
          pre = "(\n"
          args= indent 1, args
          post= "\n)"
        end
      end
      "#{k[0]}#{pre}#{args}#{post}"
    else
      k[0]
    end

    case v
    when String
      string += "\n#{k_string}"
    else
      pre= ' {'
      post= "\n}"
      if args= hash_to_graphql_query(v)
        #if args.lines.size > 1
        #  pre+= "\n"
        #end
      end
      string += "\n#{k_string}#{pre}" + indent($level + 1, args) + post
    end
  end
  $level = 0 if $level < 0
  string
end

def shorten(s)
  s= s.dup
  s.gsub! '::Spree::GraphQL::Schema::', ''
  s.gsub! '::GraphQL::', ''
  s.gsub! /(?<!, null: true)\]/, '!]'
  s.gsub! ', null: true', ''
  s.gsub! ', null: false', '!'
  s.gsub! ', required: false', ''
  s.gsub! ', required: true', '!'
  s
end

def old_to_new_name(t)
  name = t['name'].dup

  # If name has already been figured out.
  if $catalog[:type_names][name]
    return $catalog[:type_names][name]
  end

  ret= ( if t['kind'] == 'INTERFACE'
    name.sub! /Interface$/, ''
    'Interfaces::'
  elsif t['kind'] == 'INPUT_OBJECT' || t['name'] =~ /Input(?:V\d+)?$/
    name.sub! /Input(V\d+)?$/, '\1'
    'Inputs::'
  elsif t['name'] =~ /Payload(?:V\d+)?$/
    name.sub! /Payload(V\d+)?$/, '\1'
    'Payloads::'
  else
    name.sub! /Connection$/, ''
    'Types::'
  end ) + name
  if !ret
    STDERR.puts "old_to_new_name() failed for #{t['name']}; exiting."
    exit 1
  end
  ret
end

def indent(i = 0, string)
  lines = string.lines
  new_lines = []
  lines.each do |l|
    l.chomp!
    if l=~ /^\s*$/
      new_lines.push ''
    else
      new_lines.push ('  '*i)+ l
    end
  end
  new_lines.join "\n"
end

def oneline(s)
  return '' unless s
  s.sub! /^\n+/, ''
  s.sub! /\n+$/, ''
  s.gsub! "\n", ' '
  s.sub! /\s+$/, ''
  s
end

def wrap_to_connection(content)
  { [:edges] => { [:node] => content}, [:pageInfo] => { [:hasNextPage] => '', [:hasPreviousPage] => ''}}
end

####
run
