

class Metadata
  attr_reader :path, :id, :filename

  def initialize(id:, path:, filename:)
    @path = path
    @id = id
    @filename = filename
  end

  def Metadata.get_children(id: '0', base_path: '', count: true)
    path = id == '0' ? base_path : File.join(base_path, id)
    Dir["#{path}/*"].map {|file|
      id = file.gsub("#{base_path}/", '')
      if File.directory?(file)
        if count
          child_count = Metadata.get_children(id: id, base_path: base_path, count: false).size
        else
          child_count = 0
        end

        DirectoryMetadata.new(id: id, path: path,
                              filename: File.basename(file),
                              child_count: child_count)

      elsif (json = `avprobe -show_format -of json #{file} 2>/dev/null`) && $? == 0
        VideoMetadata.new(id: id, path: path, filename: File.basename(file))
      else
        nil
      end
      
    }.compact
  end

  def to_s
    filename
  end

end

class DirectoryMetadata < Metadata
  attr_reader :child_count
  def initialize(child_count: nil, **params)
    super(**params)
    @child_count = child_count
  end
end

class VideoMetadata < Metadata
  attr_reader :title, :formats, :size
  attr_reader :no_streams

  def initialize(title:, formats: [], size:, no_streams:, **params)
    super(**params)
    @title = title
    @formats = formats
    @no_streams = no_streams
  end
end
