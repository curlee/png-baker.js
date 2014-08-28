# PNGBaker class
-----

The main PNGBaker class.


    class PNGBaker

## constructor
-----

Takes a URI or ArrayBuffer as argument.

      constructor: (thing) ->

Check if argument passed is expected type.

        buffer = thing
        if typeof thing == 'string'
          buffer = @_dataURLtoBuffer thing

        if not buffer instanceof ArrayBuffer
          throw new Error "first argument must be a data URI or ArrayBuffer"

        @buffer = buffer
        @textChunks = {}
        @_chunks = []
        @PNG_SIGNATURE = [137, 80, 78, 71, 13, 10, 26, 10]

        @_ensurePNGsignature()

        i = @PNG_SIGNATURE.length
        while i < buffer.byteLength
          i += @_readNextChunk i

Throw errors if invalid chunks found.

        if not @_chunks.length || @_chunks[0].type is not "IHDR"
          throw new Error "first chunk must be IHDR"
        if @_chunks[@_chunks.length - 1].type is not "IEND"
          throw new Error "last chunk must be IEND"

## _ensurePNGsignature
-----

      _ensurePNGsignature: ->
        bytes = new Uint8Array @buffer, 0, @PNG_SIGNATURE.length
        i = 0
        while  i < @PNG_SIGNATURE.length
          if bytes[i] is not @PNG_SIGNATURE[i]
            throw new Error "PNG signature mismatch at byte " + i
          i++

## _readNextChunk
-----

      _readNextChunk: (byteOffset) ->
        i = byteOffset
        buffer = @buffer
        data = new DataView buffer
        
        chunkLength = data.getUint32 i
        i += 4
        
        crcData = new Uint8Array buffer, i, chunkLength+4
        ourCRC = @_crc32 crcData
        
        chunkType = @_arrayToStr new Uint8Array(buffer, i, 4)
        i += 4
        
        chunkBytes = new Uint8Array buffer, i, chunkLength
        i += chunkLength

        chunkCRC = data.getUint32 i
        i += 4

        if chunkCRC != ourCRC
          throw new Error "CRC mismatch for chunk type " + chunkType
        
        if chunkType == 'tEXt'
          @_readTextChunk chunkBytes
        else if chunkType == 'iTXt'
          @_readiTxtChunk chunkBytes
        else @_chunks.push {
          type: chunkType
          data: chunkBytes
        }

        return i - byteOffset

## _readiTxtChunk
-----

todo - also parse compression_flag, compression_method,
language_tag, translated_keyword http://www.w3.org/TR/PNG/#11iTXt

      _readiTxtChunk: (bytes) ->
        nullsEncountered = 0
        i = 0
        while i < bytes.length
          if bytes[i] == 0 and nullsEncountered == 0
            keyword = @_arrayToStr [].slice.call(bytes, 0, i)
            nullsEncountered++
          else if bytes[i] == 0 and nullsEncountered == 3
            text = @_arrayToStr [].slice.call(bytes, i+1)
            break
          else if bytes[i] == 0
            nullsEncountered++
          i++
        if not keyword
          throw new Error "malformed iTXt chunk"
        
        @textChunks[keyword] = text

## _readTextChunk
-----

      _readTextChunk: (bytes) ->
        i = 0
        while i < bytes.length
          if bytes[i] == 0
            keyword = @_arrayToStr [].slice.call(bytes, 0, i)
            text = @_arrayToStr [].slice.call(bytes, i+1)
            break
          i++
        if not keyword
          throw new Error "malformed tEXt chunk"
        
        @textChunks[keyword] = text

## _arrayToStr
-----

      _arrayToStr: (array) ->
        return [].map.call(
          array,
          (charCode)->
            return String.fromCharCode charCode
        ).join ''

## _strToArray
-----

http://stackoverflow.com/a/7261048

      _strToArray: (byteString) ->
        buffer = new ArrayBuffer byteString.length
        bytes = new Uint8Array buffer

        i = 0
        while i < byteString.length
          bytes[i] = byteString.charCodeAt i
          i++
        return bytes

## _dataURLtoBuffer
-----  

http://stackoverflow.com/a/7261048

convert base64 to raw binary data held in a string
doesn't handle URLEncoded DataURIs - see SO answer #6850276 for code
that does this.

      _dataURLtoBuffer: (url)->
        byteString = atob url.split(',')[1]

        return @_strToArray(byteString).buffer

## reverse
-----

      reverse: (x, n) ->
        b = 0
        while n
          b = b * 2 + x % 2
          x /= 2
          x -= x % 1
          n--
        return b

## _crc32
-----

https://gist.github.com/Yaffle/1287361

      _crc32: (s) ->
        polynomial = 0x04C11DB7
        initialValue = 0xFFFFFFFF
        finalXORValue = 0xFFFFFFFF
        crc = initialValue
        table = []

        i = 255
        while i >= 0
          c = @reverse i, 32

          j = 0
          while j < 8
            c = ((c * 2) ^ (((c >>> 31) % 2) * polynomial)) >>> 0
            j++

          table[i] = @reverse c, 32
          i--


This is a fix for Safari, which dislikes Uint8 arrays, but only
when Web Inspector is disabled.

        s = [].slice.call s

        i = 0
        while i < s.length
          c = s[i]
          if c > 255
            throw new RangeError()
          j = (crc % 256) ^ c
          crc = ((crc / 256) ^ table[j]) >>> 0
          i++

        return (crc ^ finalXORValue) >>> 0

## _makeChunk
-----

      _makeChunk: (chunk) ->
        buffer = new ArrayBuffer chunk.data.length + 12
        data = new DataView buffer
        crcData = new Uint8Array buffer, 4, chunk.data.length + 4

        data.setUint32 0, chunk.data.length
        i = 0
        while i < 4
          data.setUint8 4 + i, chunk.type.charCodeAt(i)
          i++

        i = 0
        while i < chunk.data.length
          data.setUint8 8 + i, chunk.data[i]
          i++
        
        data.setUint32 8 + chunk.data.length, @_crc32(crcData)
        return buffer

## toBlob
-----

      toBlob: ()->
        parts = [new Uint8Array(@PNG_SIGNATURE).buffer]
        makeChunk = @_makeChunk.bind @

        parts.push makeChunk(@_chunks[0])

        parts.push.apply parts, Object.keys(@textChunks).map (k) =>
          return makeChunk {
            type: 'tEXt'
            data: @_strToArray k + '\0' + @textChunks[k]
          }

        parts.push.apply parts, @_chunks.slice(1).map makeChunk

        return new Blob parts, {type: 'image/png'}

Export the module.

    module.exports = PNGBaker