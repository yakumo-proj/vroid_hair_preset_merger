#!/usr/bin/ruby

# hair_preset extract tools
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

require 'rbconfig'
class PresetJson
    def initialize(path)
        @path = path
        @json = JSON.parse(open(@path).readlines.join)
    end
    def disp_name
        @json['_DisplayName']
    end
    def disp_name=(name)
        return if self.disp_name == name
        @json['_DisplayName'] = name
        File.open(@path, mode = 'w') {|f| 
            f.write( JSON.generate @json ) 
        }
    end
end

case RbConfig::CONFIG['host_os']
when /darwin|mac os/ #MacOS
    app_name =  "com.Company.ProductName"
    path = "#{Dir.home}/Library/Application Support/#{app_name}/hair_presets/"
when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    #Windows
    path = "#{Dir.home}/AppData/LocalLow/pixiv/VRoidStudio/hair_presets/"
else
    return
end

presets = Dir.chdir(path) { 
    Dir.glob("preset*/preset.json").map{|json| 
        [json[6..-12].to_i, PresetJson.new(path+json)]
    }.sort_by(&:first)
}.to_h

if  ARGV[0] == 'update' # write mode
    open("vroid_hair_presets.csv").readlines.map {|str|
        n, name = str.chomp.split(',')
        presets[n.to_i].disp_name = name
    }
    puts "hair_presets updated."
else #csv export mode
    open("vroid_hair_presets.csv", mode = 'w') {|f| 
        presets.map { |k,v| f.puts "#{k},#{v.disp_name}" } 
    }
    puts "vroid_hair_presets.csv written."
end
