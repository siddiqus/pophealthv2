class ImportArchiveJob
  attr_accessor :file, :current_user

  def initialize(options)
    @file = options['file'].path
    @current_user = options['user']
    @practice = options['practice']
  end

  def before
    Log.create(:username => @current_user.username, :event => 'record import')
  end

  def perform
    HealthDataStandards::Import::BulkRecordImporter.import_archive(File.new(@file), @practice )
  end

  def after
    File.delete(@file)
  end
end
