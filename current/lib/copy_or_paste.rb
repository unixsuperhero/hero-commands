
class CopyOrPaste
  class << self
    def copy(text, with_newline=false)
      cmd = with_newline ? 'echo' : 'printf'
      system(cmd, text.chomp, '| pbcopy')
    end

    def paste(text=nil)
      system('pbpaste')
    end
  end
end

