#!/usr/bin/ruby1.8 -w
#
# Copyright:: Copyright 2009 Google Inc.
# Original Author:: Ryan Brown (mailto:ribrdb@google.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java'
require 'rubygems'

class Gemlet
  import java.io.FileOutputStream
  import java.util.jar.JarOutputStream
  import java.util.zip.ZipEntry
  
  def initialize(filename)
    @jarfile = JarOutputStream.new(FileOutputStream.new(filename))
    @excludes = {}
    @installed = {}
    @dirs = {}
    write_stubs
    if block_given?
      begin
        yield self
      ensure
        self.close
      end
    end
  end
  
  def write_stubs
    dir = [File.dirname(__FILE__), 'gemlets']
    write_directory(dir, dir)
  end
  
  def write_file(name, root, directory=false)
    zip_name = name[root.size, name.size].join('/')
    if directory
      zip_name << '/'

      # don't duplicate directory entries when several gems include the same
      # directory.
      return if @dirs[zip_name]
      @dirs[zip_name] = true
    end

    entry = ZipEntry.new(zip_name)
    @jarfile.put_next_entry(entry)
    unless directory
      open(File.join(name)) do |file|
        data = file.read
        @jarfile.write(data.to_java_bytes, 0, data.size)
      end
    end
    @jarfile.close_entry
  end
  
  def exclude(*names)
    names.each do |name|
      @excludes[name] = true
    end
  end
  
  def exclude?(name)
    @excludes[name]
  end

  def install(*gems)
    gems.each do |gem|
      if gem.kind_of? Array
        gem, version = gem
      else
        version = Gem::Requirement.default
      end
      install_gem(gem, version)
    end
  end
  
  def install_gem(gem, version=nil)
    unless gem.respond_to?(:name) and
           gem.respond_to?(:version_requirements) then
      gem = Gem::Dependency.new(gem, version)
    end
    return if exclude?(gem.name)
    
    # activate to detect version conflicts
    Gem.activate(gem)
    
    install_loaded_spec(Gem.loaded_specs[gem.name])
  end
  
  def install_loaded_gems
    Gem.loaded_specs.each do |spec|
      unless exclude?(spec.name)
        install_loaded_spec(spec)
      end
    end
  end
  
  def install_loaded_spec(spec)
    return if @installed[spec.name]
    @installed[spec.name] = true
    spec.runtime_dependencies.each do |dependency|
      install_gem(dependency)
    end
    
    spec.require_paths.each do |path|
      next if path == spec.bindir
      dir = [spec.full_gem_path, path]
      write_directory(dir, dir)
    end
  end
  
  def write_directory(name, root)
    dir = File.join(name)
    return unless File.directory?(dir)
    
    write_file(name, root, true) unless name == root
    Dir.foreach(dir) do |path|
      next if ['.', '..'].include?(path)

      child = name + [path]
      if File.directory?(File.join(child))
        write_directory(child, root)
      else
        write_file(child, root, false)
      end
    end
  end
  
  def write_installed_gems
    entry = ZipEntry.new('installed_gemlets.rb')
    @jarfile.put_next_entry(entry)
    data = <<EOF
class Gemlet
  INSTALLED_GEMLETS = #{@installed.inspect}
end    
EOF
    @jarfile.write(data.to_java_bytes, 0, data.size)
    @jarfile.close_entry
  end
  
  def close
    write_installed_gems
    @jarfile.close
  end
end