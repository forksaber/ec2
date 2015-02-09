require 'ec2/logger'
module Ec2
  class Lock

    include Logger

    def acquire
      logger.debug "acquiring lock"
      lock_acquired = lock_file.flock(File::LOCK_NB | File::LOCK_EX)
      raise "exclusive lock not available" if not lock_acquired
    end

    def lock_file
      @lock_file ||= File.open(".ec2.lock", "a+")
    end

  end
end

