#!/usr/bin/env ruby

# hair_preset marge tools ver.0.6
# Copyright (C) 2020-2021 Yakumo Sayo, Susanoo Lab. All rights reserved.
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

# usage: ruby hair_merge.rb presetXXX presetYYY presetZZZ <options>
#  options:
#    -d, --dispname name      : merged hair-preset display name (top["_DisplayName"]).
#    -p, --preset-dir-num nnn : preset directory number
# => directory 'presetNNN' merged

require 'rbconfig'
require 'JSON'
require 'fileutils'
require 'digest'
require 'securerandom'
require 'optparse'
require 'pathname'

PRESET_DISP_PREFIX = 'プリセット'

class VRoidHairsNode
    def initialize(path)
        @path = path
        @node = JSON.parse(open(path + '/preset.json', max_nesting:false).readlines.join)
        @hairishes = @node['Hairishes']
        @materials = @node['_MaterialSet']['_Materials']
        @bones     = @node['_HairBoneStore']['Groups']
        @textures = Dir.chdir(path + '/materials/rendered_textures/') { 
            Dir.glob('*.png').map{|file| file.split('.').first }
        }
    end
     
    public
    def self.texture_path(base_path, uuid)
        "#{base_path}/materials/rendered_textures/#{uuid}.png"
    end

    def make_dest(target_path, display_name)
        @target_path = target_path
        @display_name = display_name
        texture_dir_path = "#{@target_path}/materials/rendered_textures/"
        FileUtils.mkdir_p(texture_dir_path) 
        FileUtils.cp_r(Dir.glob(@path+'/materials/rendered_textures/*'), texture_dir_path )
    end

    def merge_finish
        @node['Hairishes'] = @hairishes
        @node['_MaterialSet']['_Materials'] = @materials
        @node['_HairBoneStore']['Groups'] = @bones        
        @node['_DisplayName'] = @display_name || 
            (PRESET_DISP_PREFIX + @target_path.split('/').last[6..-1])
        json = JSON.generate(@node)
        File.open(@target_path+'/preset.json', mode = 'wb') {|f| f.write(json) }        
    end

    def remove_dest
        return unless @target_path
        FileUtils.rm_r(@target_path)
        @target_path = nil
    end

    def new_empty_hash
        Hash.new{|hash,key|key}
    end

    def merge_proc(other)
        #textures
        conflicts = @textures & other.textures
        if conflicts.size > 0 
            trans_textures = conflicts.reject {|uuid| 
                [other.path, @target_path].map {|path|
                    Digest::SHA256.file(VRoidHairsNode.texture_path(path, uuid)).hexdigest
                }.uniq.size == 1
            }.each_with_object(new_empty_hash) {|uuid,hash| 
                hash[uuid] = SecureRandom.uuid 
            }
        end

        other.textures.each {|uuid|
            dest_uuid = trans_textures[uuid] || uuid
            dest = VRoidHairsNode.texture_path(@target_path, dest_uuid) 
            unless File.exist?(dest) 
                @textures += dest_uuid
                FileUtils.cp(VRoidHairsNode.texture_path(other.path, uuid), dest)
            end
        }
        @textures.uniq!

        #materials
        a_node,b_node = [@materials, other.materials].map{|mat|
            mat.each_with_object({}) {|x,h| h[x['_Id']] = x } 
        }
        conflicts = a_node.keys & b_node.keys
        # ダイレクトにコピーしとく
        (b_node.keys - conflicts).each{|ids|
            @materials << b_node[ids]
        }
        # まったく同じマテリアルは除外
        conflicts = conflicts.reject {|ids|
            a = a_node[ids]
            b = b_node[ids]
            a['_MainTextureId'] == b['_MainTextureId'] && 
            trans_textures[ b['_MainTextureId'] ].nil? &&
            ['_Color', '_ShadeColor', '_HighlightColor', '_OutlineColor'].all? {|color|
                ['r', 'g', 'b'].all? {|rgb| 
                    a[color][rgb] == b[color][rgb] 
                }
            }
        }

        # マテリアルとUUIDの対応
        trans_materials = conflicts.each_with_object(new_empty_hash) {|ids,h| 
            h[ids] = SecureRandom.uuid 
        }  

        # ID競合するマテリアルをID振り替えて登録
        trans_materials.each{|ids,uuid|
            node = b_node[ids]
            node['_Id'] = uuid
            node['_MainTextureId'] = trans_textures[node['_MainTextureId']]
            @materials << node
        }

        #hairishes
        # めんどくさいから全部新ID割り当て
        trans_hairs = new_empty_hash
        hairs = other.hairishes
        hairs.reject! {|hairs_grp| hairs_grp['Type'].to_i == 3 } # 3: base hair
        @hairishes += hairs.map {|hairs_grp|
            update = -> (x) {
                x['Id'] = trans_hairs[x['Id']] = SecureRandom.uuid
                x['Param']['_MaterialValueGUID'] = trans_materials[x['Param']['_MaterialValueGUID']] 
                x['Param']['_MaterialInheritedValueGUID'] = trans_materials[x['Param']['_MaterialInheritedValueGUID']] 
                x
            }
            hairs_grp['Children'].map! {|hair| update[hair] }
            update[hairs_grp]
        }
        # bones
        @bones += other.bones.map {|bone|
            bone['Id'] = SecureRandom.uuid
            bone['Hairs'].map! {|hair| trans_hairs[hair] }
            bone['Joints'].map! {|joint|
                joint['Name'] = 'HairJoint-' + SecureRandom.uuid
                joint
            }
            bone['AxisHintHairIds'].map! {|hair| trans_hairs[hair] }
            bone
        }
    end

    attr_accessor :path, :hairishes, :materials, :bones, :textures
end

class VRoidHairsMerger
    public
    def self.presets_directory
        @@presets_path ||= (
            app_name =  'com.Company.ProductName'
            path = Pathname.new(Dir.home)
                .join("Library/Application Support/#{app_name}/hair_presets")
                .to_s 
            path
        )
    end

    def self.next_preset_num
        Dir.chdir(presets_directory) { 
            Dir.glob('preset*/preset.json').map{|path| 
                path.delete('^0-9').to_i
            }.max + 1
        }
    end

    def self.run(path_list, target_path, display_name)
        base_node = VRoidHairsNode.new(path_list.pop)       
        begin 
            base_node.make_dest(target_path, display_name)
            path_list.each {|other_path|
                base_node.merge_proc(VRoidHairsNode.new(other_path))
            }
            base_node.merge_finish
        rescue => e
            FileUtils.rm_r(target_path)
           raise e
        end
    end
end

# handle options
$app_options = {}
OptionParser.new {|opt|
    params = {
        disp_name: ["-d", "--dispname name",   "merged hair-preset display name"],
        preset_no: ["-p", "--preset-dir-num nnn",  "preset directory number"],
    }
    params.each {|id, o| opt.on(*o) {|v| $app_options[id] = v } }
    opt.parse! ARGV
}

$app_options[:preset_no] ||= VRoidHairsMerger.next_preset_num
$app_options[:disp_name] ||= PRESET_DISP_PREFIX + $app_options[:preset_no].to_s
preset_next = Pathname.new(VRoidHairsMerger.presets_directory).join(
    "preset#{$app_options[:preset_no]}").to_s
VRoidHairsMerger.run(ARGV, preset_next, $app_options[:disp_name])
puts preset_next + ' created.'