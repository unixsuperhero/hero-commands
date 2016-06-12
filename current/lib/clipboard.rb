
class Clipboard
  class << self
    def copy(text, with_newline=false)
      Shell.new.transact{|sh| sh.system('printf', text) | sh.system('pbcopy') }
    end

    def show_copied_text
      system(%{printf 'The text copied was: "%s"' "$(pbpaste)"})
    end

    def paste(text=nil)
      system('pbpaste')
    end
  end
end



# vim: ft=ruby
