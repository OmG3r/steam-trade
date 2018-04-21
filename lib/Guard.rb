module GuardCommands





      def fa()
            timestamp = Time.new.to_i
            math = timestamp / 30
            math = math.to_i
            time_buffer =[math].pack('Q>')

            hmac = OpenSSL::HMAC.digest('sha1', Base64.decode64(@secret), time_buffer)

            start = hmac[19].ord & 0xf
            last = start + 4
            pre = hmac[start..last]
            fullcode = pre.unpack('I>')[0] & 0x7fffffff

            chars = '23456789BCDFGHJKMNPQRTVWXY'
            code= ''
            for looper in 0..4 do
                  copy = fullcode #divmod
                  i = copy % chars.length #divmod
                  fullcode = copy / chars.length #divmod
                  code = code + chars[i]
            end
            return code

      end

      def generate_confirmation_key(tag_string, time_stamp)
            buffer = [time_stamp].pack('Q>') + tag_string.encode('ascii')
            return Base64.encode64(OpenSSL::HMAC.digest('sha1', Base64.decode64(@identity_secret), buffer))
      end


      def generate_device_id()
            hexed = Digest::SHA1.hexdigest(@steamid.to_s)
            res = 'android:' + [hexed[0..7],hexed[8..11],hexed[12..15],hexed[16..19],hexed[20..31]].join('-')
            return res
      end

end
