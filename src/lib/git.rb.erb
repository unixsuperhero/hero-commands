class Git
  class << self
    def current_branch
      `git rev-parse --symbolic-full-name HEAD`.chomp.split(?/,3).last
    end

    def status
      `git status -s`.lines.flat_map{|line|
        line.chomp.sub(/.../,'').split(/\s+->\s+/)
      }.uniq
    end

    def branches
      `git branch`.lines.flat_map{|line|
        line.split(/\s+/).select{|b| b[/\w/] }
      }.uniq
    end

    def branch_parts(branch=current_branch)
      parts = branch.split(?/)
      base = parts.pop
      prefix = parts.join(?/)
      DotHash.new({base: base,
                      has_prefix: parts.count > 0,
                      prefix: parts.join(?/)})
    end

    def branch_base
      branch_parts.base
    end

    def branch_has_prefix?
      branch_parts.has_prefix
    end

    def branch_prefix
      branch_parts.prefix
    end
  end
end


# vim: ft=ruby
