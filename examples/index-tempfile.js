const { spawn } = require('child_process')
const fs = require('fs')
const path = require('path')
const os = require('os')

function generateTone(freq, duration = 1, amp = 0.2) {
  const sampleRate = 44100
  const samples = Math.floor(sampleRate * duration)
  const audio = new Float32Array(samples)

  for (let i = 0; i < samples; i++) {
    const t = i / sampleRate
    audio[i] = amp * Math.sin(2 * Math.PI * freq * t)
  }

  return audio
}

function playAudio(audioData) {
  // Use correct executable path for Windows
  const exe = process.platform === 'win32' ? 'play_buffer.exe' : './play_buffer.exe'

  if (!fs.existsSync(exe)) {
    console.log('play_buffer.exe not found - build it first')
    return
  }

  console.log(`Generated ${audioData.length} samples (${(audioData.length / 44100).toFixed(2)} seconds)`)

  // Create temporary file instead of using pipes
  const tempFile = path.join(os.tmpdir(), `playbuffer_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.raw`)
  
  try {
    // Convert Float32Array to Buffer
    const buffer = Buffer.from(new Uint8Array(audioData.buffer, audioData.byteOffset, audioData.byteLength))
    
    console.log(`Writing ${buffer.length} bytes to temporary file: ${tempFile}`)
    console.log(`Expected: ${audioData.length * 4} bytes`)
    
    // Write to temporary file
    fs.writeFileSync(tempFile, buffer)
    console.log('Temporary file written successfully')
    
    // Verify file size
    const stats = fs.statSync(tempFile)
    console.log(`Temporary file size: ${stats.size} bytes`)
    
    // Spawn play_buffer with file redirection
    console.log('Starting play_buffer with file input...')
    const player = spawn(exe, [], { 
      stdio: ['pipe', 'inherit', 'inherit']
    })

    player.on('error', (err) => {
      console.log('Failed to start play_buffer:', err.message)
      // Clean up temp file
      try { fs.unlinkSync(tempFile) } catch {}
    })

    player.on('close', (code) => {
      console.log(`play_buffer process exited with code ${code}`)
      // Clean up temp file
      try { 
        fs.unlinkSync(tempFile)
        console.log('Temporary file cleaned up')
      } catch (err) {
        console.log('Warning: Could not clean up temporary file:', err.message)
      }
    })

    // Read the temp file and pipe it to stdin
    const fileStream = fs.createReadStream(tempFile)
    
    fileStream.on('error', (err) => {
      console.log('File read error:', err.message)
    })
    
    player.stdin.on('error', (err) => {
      console.log('Stdin error:', err.message)
    })

    player.stdin.on('close', () => {
      console.log('Stdin closed')
    })

    // Pipe the file to play_buffer
    fileStream.pipe(player.stdin)
    
  } catch (err) {
    console.log('Error with temporary file approach:', err.message)
    // Clean up temp file on error
    try { fs.unlinkSync(tempFile) } catch {}
  }
}

// Generate 10 second polyphonic composition
const duration = 10
const amp = 0.15

// Multiple harmonic frequencies for rich polyphony
const frequencies = [
  261.63, // C4
  329.63, // E4
  392.00, // G4
  523.25, // C5
  659.25, // E5
  783.99, // G5
  146.83, // D3
  220.00, // A3
]

// Generate all tones
const tones = frequencies.map(freq => generateTone(freq, duration, amp))

// Mix all tones together
const polyphone = new Float32Array(tones[0].length)
for (let i = 0; i < polyphone.length; i++) {
  let sum = 0
  for (const tone of tones) {
    sum += tone[i]
  }
  polyphone[i] = sum / tones.length // Normalize to prevent clipping
}

playAudio(polyphone)