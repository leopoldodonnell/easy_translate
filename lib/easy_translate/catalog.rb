require 'yaml'
require 'active_support/core_ext/hash'

module EasyTranslate

  module Catalog
    
    # Set a debug translator block that will receive a String
    # and respond with translated String.
    #
    # This is useful for development when you don't necessarily
    # want to go out to google for translation each run.
    def debug_translator(&block)
      @debug_translator = block
    end
    
    # Create a Rails Language Catalogs (locale dictionary) for one or more languages
    # by translating a source Catalog.
    #
    # @param [String] catalog_filename - the full path to a language catalog to translate.
    # @param [String, splat] languages - a splat array of google language codes to translate.
    #
    def translate_catalog!(catalog_filename, *languages)
      _translate_catalog(catalog_filename, true, *languages)
    end

    # Create or Update a Rails Language Catalog (locale dictionary) for one or more 
    # languages by translating a source catalog.
    #
    # Updates are non-destructive in that they do not replace any existing translations
    # in the translated files.
    #
    # @param [String] catalog_filename - the full path to a language catalog to translate.
    # @param [String, splat] languages - a splat array of google language codes to translate.
    #
    def translate_catalog(catalog_filename, *languages)
      _translate_catalog(catalog_filename, false, *languages)
    end
      
    private
    
    # Translate the language in a catalog (locale ditionary) into one or more languages.
    # Write the output to files derived from the source catalog's filename by replacing
    # the google language code.
    #
    # @param [String] catalog_filename - the full path to a language catalog to translate.
    # @param [Boolean] allow_overwrites - replace any existing translations in the destination
    # translations with the translation from the source catalog.
    # @param [String, splat] languages - a splat array of google language codes to translate.
    #
    def _translate_catalog(catalog_filename, allow_overwrites, *languages)
      catalog_hash  = YAML::load(File.open catalog_filename)
      from_language = catalog_hash.keys.first

      source_html = catalog_hash.to_xml
      
      languages.each { |to_language|
        translated_hash = translate_html(source_html, from_language, to_language)
        
        # fix the language identifier in the translated file to the new language
        translated_hash[to_language] = translated_hash.delete from_language

        to_filename = get_to_filename(catalog_filename, from_language, to_language)
        
        translated_hash = merge_translation(to_filename, translated_hash) unless allow_overwrites

        write_translated_file(to_filename, translated_hash)
      }
    end
    
    # Generate the 'to' filename by replacing the 'from' language code
    # in the 'from' filename.
    def get_to_filename(from_filename, from_language, to_language)
      from_filename.gsub(Regexp.new("#{from_language}\."), "#{to_language}.")
    end

    # Merge the new translation into the old translation if it exists
    #
    # @returns the merged translation
    def merge_translation(filename, translated_hash)
      return translated_hash unless File.exists? filename
      
      prev_translation = YAML::load(File.open filename) 
      recursive_merge(translated_hash, prev_translation)
    end
    
    # Recursive merge new items from one hash into another
    # without clobbering the original items.
    #
    # @param [Hash] new_hash - has the newer items
    # @param [Hash] old_hash - has the original items
    def recursive_merge(new_hash, old_hash)
      # Merge in this level using the old translation when it exists
      new_hash.each { |key, value|
        if value.kind_of? Hash and old_hash.has_key? key
          recursive_merge(value, old_hash[key])
        elsif old_hash.has_key? key
          new_hash[key] = old_hash[key]
        end
      }
    end
        
    # Create or overwrite the translated Catalog with owner rw and
    # group|other as read only.
    def write_translated_file(filename, translated_hash)
      translated_file = File.new(filename, File::CREAT|File::TRUNC|File::RDWR, 0644)    
      translated_file << translated_hash.to_yaml
      translated_file.close
    end
    
    def translate_html(html, from_language, to_language)
      if @debug_translator
        debug_translation(Hash.from_xml(html)['hash'])
      else
        Hash.from_xml(unescape(self.translate(escape html, :from => from_language.to_sym, :to => to_language.to_sym)))['hash']
      end
    end
    
    # Prevent control characters from being translated by putting them
    # into a 'notranslate' span
    def escape(html)
      html.gsub(/(\\[nrt])+|(\{\S*\})/, "<span class='notranslate'>\\0</span>")
    end
    
    # Remove the 'notranslate' spans from html
    def unescape(html)
      html.gsub(/<span class='notranslate[^>]+>([^<]*)<\/span>/,"\\1")
    end

    # Use the debug_translation block to translate items.
    def debug_translation(hash)
      hash.each { |key, value|
        if value.kind_of? Hash
          debug_translation value
        else
          hash[key] = @debug_translator.call(value) if value
        end
      }
    end
    
  end
end
