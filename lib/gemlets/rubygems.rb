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

module Kernel
  def gem(name, *args)
    require 'installed_gemlets'
    unless Gemlet::INSTALLED_GEMLETS[name]
      raise Gem::LoadError, "Gemlet #{name} not installed."
    end
  end
  
  private :gem
end

module Gem
  RubyGemsVersion = '1.3.1'
  class LoadError < ::LoadError; end
  class Exception < RuntimeError; end
  
  class Specification
    attr_accessor :installation_path
  end
  
  class Version
    def self.new(version)
      return version
    end
  end
  
  def self.activate(*args)
  end
  
  def self.loaded_specs
    {}
  end
  
  def path
    []
  end
  
  def clear_paths
  end
end