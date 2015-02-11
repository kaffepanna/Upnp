

class Metadata
  attr_reader :path, :id, :filename, :parent_id

  def initialize(id:, parent_id:, path:, filename:)
    @path = path
    @id = id
    @filename = filename
    @parent_id = parent_id
  end

  def mtime
    File.mtime(File.join(path, filename))
  end

  def Metadata.get_metadata(id: '0', base_path: '')
    path = id == '0' ? base_path : File.join(base_path, id)

    filename = 'root'
    filename = File.basename(path) unless id == '0'

    if id == '0'
      pid = '-1'
    else
      pid = File.dirname(path).gsub("#{base_path}/", "")
    end
    
    cid = id

    puts "Collecting metadata for #{path} id: #{cid} filename: #{filename} parent: #{pid}"
     if File.directory?(path)
        DirectoryMetadata.new(id: cid, path: path, parent_id: pid,
                              filename: filename)
     end
  end

  def Metadata.get_children(id: '0', base_path: '')
    path = id == '0' ? base_path : File.join(base_path, id)
    Dir["#{path}/*"].map {|file|
      cid = file.gsub("#{base_path}/", '')
      if File.directory?(file)
        DirectoryMetadata.new(id: cid, path: path, parent_id: id,
                              filename: File.basename(file))

      elsif (json = `avprobe -show_format -of json #{file} 2>/dev/null`) && $? == 0
        VideoMetadata.new(id: cid, parent_id: id,
                          path: path,
                          filename: File.basename(file) )
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
  def child_count
    Metadata.get_children(id: id, base_path: path.gsub("/#{id}", "")).size
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
