module Gexcore
  class ImagesHelpers
    ### for round avatar
    def self.convert_options(px = 50) # only for :thumb => ["100x100#",:png]
      trans = ""
      trans << " \\( +clone  -alpha extract "
      trans << "-draw 'fill black polygon 0,0 0,#{px} #{px},0 fill white circle #{px},#{px} #{px},0' "
      trans << "\\( +clone -flip \\) -compose Multiply -composite "
      trans << "\\( +clone -flop \\) -compose Multiply -composite "
      trans << "\\) -alpha off -compose CopyOpacity -composite "
    end
  end
end
