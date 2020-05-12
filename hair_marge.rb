# hair_presets marge tools ver.0.1 (GNU GPLv3 ver.)
# Copyright (C) 2020  Yakumo Sayo, Susanoo Lab. All rights reserved.
# usage: ruby hair_marge.rb presetXXX presetYYY
#  => directory 'presetXXX' marged.

#!/usr/bin/ruby
require 'JSON'
require 'fileutils'

#marge JSON
x, y = ARGV[0..1].map {|path| JSON.parse( open(path + '/preset.json').readlines.join) }
x["Hairishes"]                  += y["Hairishes"][1..-1]
x["_MaterialSet"]["_Materials"] += y["_MaterialSet"]["_Materials"]
x["_HairBoneStore"]["Groups"]   += y["_HairBoneStore"]["Groups"]

#write JSON
File.open(ARGV[0] + '/preset.json', mode = 'w') {|f| f.write(JSON.generate(x)) }

#copy textures
textures = "/materials/rendered_textures/"
FileUtils.cp_r(  Dir.glob(ARGV[1] + textures + "*"), ARGV[0] + textures )
