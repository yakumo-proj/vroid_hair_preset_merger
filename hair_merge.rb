#!/usr/bin/ruby

# hair_preset marge tools ver.0.2
# Copyright (C) 2020  Yakumo Sayo, Susanoo Lab. All rights reserved.
# 
# GPLv3
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# usage: ruby hair_merge.rb presetXXX presetYYY presetZZZ <Preset Name(option)>
#  => directory 'presetXXX' merged

require 'JSON'
require 'fileutils'
 
json_path = -> path { path + "/preset.json" }
textures_path = -> path { path + "/materials/rendered_textures/" }

# solve ID confliction
class Array
    def merge_tree!(other)
        s = self + other
        g = s.group_by {|node| node["Id"] || node["_Id"] }
        g.each{|k,v| puts " [warning] id confliction : #{k}" if v.size > 1 }
        replace g.values.map(&:last)
    end
end

# merge JSON
x,y = ARGV[0..1].map {|path| JSON.parse(open(json_path[path]).readlines.join) }
return if x.nil? || y.nil?
x['Hairishes'].merge_tree! y['Hairishes'][1..-1]
x['_MaterialSet']['_Materials'].merge_tree! y['_MaterialSet']['_Materials']
x['_HairBoneStore']['Groups'].merge_tree! y['_HairBoneStore']['Groups']

# Display Name
x['_DisplayName']= ARGV[3] || ('[merged]' + File.basenane(new_preset))

#write JSON
new_preset =  ARGV[2]
FileUtils.mkdir_p(textures_path[new_preset]) unless Dir.exists? new_preset
File.open(json_path[new_preset], mode = 'w') {|f| f.write(JSON.generate(x)) }

#copy textures
ARGV[0..1].each {|path| 
    FileUtils.cp_r( Dir.glob(textures_path[path] +"*"), textures_path[new_preset] )
}

