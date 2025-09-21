const { spawn } = require('child_process')
const fs = require('fs')

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
  const exe = './play_buffer.exe'

  if (!fs.existsSync(exe)) {
    console.log('play_buffer.exe not found - build it first')
    return
  }

  const player = spawn(exe, [], { stdio: ['pipe', 'inherit', 'inherit'] })

  player.on('error', (err) => {
    console.log('Failed to start play_buffer:', err.message)
  })

  player.stdin.on('error', (err) => {
    console.log('Stdin error (process may have closed early):', err.message)
  })

  try {
    player.stdin.write(Buffer.from(audioData.buffer))
    player.stdin.end()
  } catch (err) {
    console.log('Error writing audio data:', err.message)
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