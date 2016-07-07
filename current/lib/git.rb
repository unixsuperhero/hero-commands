class Git
  class << self
    def inside_repo?
      system(*'git rev-parse --show-cdup'.shellsplit, [:out, :err] => '/dev/null')
      # return true if `git rev-parse --is-inside-work-tree`[/true/]
      # return true if `git rev-parse --is-inside-git-dir`[/true/]
      # false
    end

    def path_to_root
      return '.' unless inside_repo?
      `git rev-parse --show-cdup`.lines.first.chomp.sub(%r{/*$}, '')
    end

    def absolute_root_path
      return '.' unless inside_repo?
      `git rev-parse --show-toplevel`.lines.first.chomp.sub(%r{/*$}, '')
    end

    def cd_to_root_path
      return false unless inside_repo?
      Dir.chdir(path_to_root)
    end

    def path_to_git_dir
      return '.' unless inside_repo?
      `git rev-parse --git-dir`.lines.first.chomp.sub(%r{/*$}, '')
    end

    def cd_to_git_dir
      return false unless inside_repo?
      Dir.chdir(path_to_git_dir)
    end

    def current_head
      return false  unless inside_repo?
      head = `git symbolic-ref HEAD`.lines.first.chomp
      head.sub(%r{^refs/heads/}, '')
    end

    def heads_dir
      File.join(path_to_git_dir, 'refs/heads')
    end

    def heads
      pwd = Dir.pwd
      Dir.chdir heads_dir

      Dir['**/*'].select{|f|
        File.file?(f)
      }.tap{
        Dir.chdir(pwd)
      }
    end
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
