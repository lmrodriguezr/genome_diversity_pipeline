#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', `which miga`)
require 'miga'

# Load ANI clusters
ARGV.empty? and abort "Usage: #{$0} /path/to/project"
p = MiGA::Project.load(ARGV.shift) or abort 'Cannot load project'
r = p.result(:clade_finding) or abort 'This project is not indexed'
gspp_path = r.file_path(:clades_ani95) or abort 'Index doesn\'t have ANI95'
gspp = File.readlines(gspp_path).map { |i| i.chomp.split(',') }

# Load quality estimates
q = {}
p.each_dataset do |dataset|
  begin
    q[dataset.name] = dataset.result(:essential_genes)[:stats][:quality]
  rescue
    abort "Cannot load quality estimate for #{dataset.name}"
  end
end

# Extract method (assembly and binning)
method = Hash[
  q.keys.map do |i|
    [i, i.gsub(/^([^_]+)_.*_([^_]+)_\d+$/, '\1_\2')]
  end
]
methods = method.values.uniq

# Find highest-quality representatives
puts (['gsp'] + methods).join("\t")
gspp.each_with_index do |gsp, k|
  rep = {}
  gsp.each do |mag|
    next if q[mag] < 30
    rep[method[mag]] ||= mag
    rep[method[mag]] = mag if q[mag] > q[rep[method[mag]]]
  end
  repq = methods.map { |m| rep[m].nil? ? 'NA' : q[rep[m]].to_s }
  next if repq.all? { |i| i == 'NA' }
  puts ([k.to_s] + repq).join("\t")
end

