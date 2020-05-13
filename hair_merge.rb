#!/usr/bin/ruby

# hair_presets merge tool ver.0.1
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

# usage: ruby hair_merge.rb presetXXX presetYYY
#  => directory 'presetXXX' merged.

require 'JSON'
require 'fileutils'

#merge JSON
x, y = ARGV[0..1].map {|path| JSON.parse(open(path + '/preset.json').readlines.join) }
x["Hairishes"]                  += y["Hairishes"][1..-1]
x["_MaterialSet"]["_Materials"] += y["_MaterialSet"]["_Materials"]
x["_HairBoneStore"]["Groups"]   += y["_HairBoneStore"]["Groups"]

#write JSON
File.open(ARGV[0] + '/preset.json', mode = 'w') {|f| f.write(JSON.generate(x)) }

#copy textures
textures = "/materials/rendered_textures/"
FileUtils.cp_r(  Dir.glob(ARGV[1] + textures + "*"), ARGV[0] + textures )
