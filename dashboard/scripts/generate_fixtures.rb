#!/usr/bin/env ruby

require_relative '../config/environment'

scripts_map = {
  'hour_of_code' => 'Hour of Code',
  'edit-code' => 'edit-code',
  'events' => 'events',
  'jigsaw' => 'jigsaw',
  'hourofcode' => 'hourofcode',
  'starwars' => 'starwars',
  'frozen' => 'frozen',
  'playlab' => 'playlab',
  'infinity' => 'infinity',
  'artist' => 'artist',
  'algebra' => 'algebra',
  'algebraPD' => 'algebraPD',
  'flappy' => 'flappy',
  '20-hour' => '20-hour',
  'course1' => 'course1',
  'course2' => 'course2',
  'course3' => 'course3',
  'course4' => 'course4',
  'cspunit1' => 'cspunit1',
  'cspunit2' => 'cspunit2',
  'cspunit3' => 'cspunit3',
  'ECSPD' => 'ECSPD',
  'ECSPD-NexTech' => 'ECSPD-NexTech',
  'allthethings' => 'allthethings'
}

@scripts = {}
@script_levels = {}
@levels = {}
@level_sources = {}
@stages = {}
@callouts = {}

def handle_level(level)
  @levels["level_#{level.id}"] = level.attributes

  level_source = level.level_sources.first
  @level_sources["level_source_#{level.id}"] = level_source.attributes if level_source
end

scripts_map.each do |_script_id, name|
  puts name
  script = Script.find_by_name name
  @scripts[name] = script.attributes

  script.stages.each do |stage|
    @stages["stage_#{stage.id}"] = stage.attributes
  end

  script.script_levels.to_a[0, 10000].each do |sl|
    key = "script_level_#{sl.script_id}_#{sl.level_id}"
    @script_levels[key] = sl.attributes
    @script_levels[key]['levels'] = sl.level_ids.map {|id| "level_#{id}"}.join(', ')

    sl.callouts.each do |c|
      @callouts["callout_#{c.id}"] = c.attributes
    end
    sl.levels.each {|level| handle_level(level)}
  end
end

ProjectsController::STANDALONE_PROJECTS.each do |_k, v|
  handle_level(Level.find_by_name(v['name']))
end

def yamlize(hsh, drop_ids=false)
  hsh.each do |_k, v|
    if v.key?("properties") && v['properties']
      v['properties'] = v['properties'].to_json
    end
    v.delete('id') if drop_ids
    v.each do |inner_key, inner_value|
      v[inner_key] = inner_value.utc if inner_value.is_a?(ActiveSupport::TimeWithZone)
    end
  end
  return hsh.to_yaml[4..-1]
end

prefix = "../test/fixtures/"

File.new("#{prefix}script.yml", 'w').write(yamlize(@scripts))
File.new("#{prefix}level.yml", 'w').write(yamlize(@levels, true))
File.new("#{prefix}script_level.yml", 'w').write(yamlize(@script_levels))
File.new("#{prefix}stage.yml", 'w').write(yamlize(@stages))
File.new("#{prefix}level_source.yml", 'w').write(yamlize(@level_sources))
File.new("#{prefix}callout.yml", 'w').write(yamlize(@callouts))
