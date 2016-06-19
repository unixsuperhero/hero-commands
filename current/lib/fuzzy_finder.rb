class FuzzyFinder
  class << self
    def best(text,pat)
      find(text,pat).first
    end

    def match(text,pat)
      find(text,pat).first
    end

    def find(text,pat)
      find(text,pat)
    end

    def all(text,pat)
      find(text,pat)
    end

    def from_left(text, char, last_index=nil, limit=nil)
      [].tap{|indexes|
        ap char: char, last_index: last_index, limit: limit
        while cur_idx = text.index(char, last_index || 0)
          break if limit && cur_idx >= limit
          indexes.push cur_idx
          last_index = cur_idx + 1
        end
      }
    end

    def from_right(text, char, last_index=nil, limit=nil)
      [].tap{|indexes|
        ap char: char, last_index: last_index, limit: limit
        while cur_idx = text.rindex(char, last_index || -1)
          break if limit && cur_idx <= limit
          indexes.push cur_idx
          last_index = cur_idx - 1
        end
      }
    end

    def find_all(text,pat)
      indexes = {left: [], right: []}

      pat.length.times.inject([]){|list,idx|
        newfind = (idx.even? ? (list.last || 0) + idx : (list.last || 0) - idx)
        list.push(newfind)
      }.each_with_index{|pat_pos,pidx|
        if pidx == 0
          indexes[:left] = from_left(text, pat[pat_pos]).map{|leftlist|
            [leftlist]
          }
        elsif pidx == 1
          indexes[:right] = from_right(text, pat[pat_pos]).map{|rightlist|
            [rightlist]
          }
        elsif pidx.even?
          limit = indexes[:right].map(&:first).max
          indexes[:left] = indexes[:left].flat_map{|lside|
            results = from_left(text, pat[pat_pos], lside.last + 1, limit)
            next [] if results.empty?
            results.map{|leftlist|
              lside.dup.push(leftlist)
            }
          }
        else
          limit = indexes[:left].map(&:last).min
          indexes[:right] = indexes[:right].flat_map{|rside|
            results = from_right(text, pat[pat_pos], rside.first - 1, limit)
            next [] if results.empty?
            results.map{|rightlist|
              rside.dup.unshift(rightlist)
            }
          }
        end
      }

      indexes[:left].flat_map{|lside|
        indexes[:right].select{|rside| lside.last < rside.first }.map{|rside| lside.dup.concat(rside) }
      }.map{|idxs|
        text[idxs.first..idxs.last]
      }.sort_by(&:length).uniq.tap{|finals|
        ap(finals: finals)
      }
    end
  end
end
