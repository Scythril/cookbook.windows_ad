module WindowsAd
  module Helper
    def strip_carriage_returns(output)
      output.gsub(/\r/, '')
    end
  end
end