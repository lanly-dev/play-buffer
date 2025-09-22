const { spawn } = require('child_process')
const fs = require('fs')

// Note frequencies (Hz)
const NOTES = {
  C4: 261.63,
  D4: 293.66,
  E4: 329.63,
  F4: 349.23,
  G4: 392.00,
  A4: 440.00,
  B4: 493.88,
  C5: 523.25
}

function generateTone(freq, duration = 0.4, amp = 0.3) {
  const sampleRate = 44100
  const samples = Math.floor(sampleRate * duration)
  const audio = new Float32Array(samples)
  for (let i = 0; i < samples; i++) {
    const t = i / sampleRate
    audio[i] = amp * Math.sin(2 * Math.PI * freq * t)
  }
  return audio
}

function generateMelody() {
  // Happy Birthday melody (notes and durations in seconds)
  // Each tuple: [note, duration]
  const melody = [
    [NOTES.G4, 0.4], [NOTES.G4, 0.4], [NOTES.A4, 0.8], [NOTES.G4, 0.8], [NOTES.C5, 0.8], [NOTES.B4, 1.2],
    [NOTES.G4, 0.4], [NOTES.G4, 0.4], [NOTES.A4, 0.8], [NOTES.G4, 0.8], [NOTES.D5, 0.8], [NOTES.C5, 1.2],
    [NOTES.G4, 0.4], [NOTES.G4, 0.4], [NOTES.G5, 0.8], [NOTES.E5, 0.8], [NOTES.C5, 0.8], [NOTES.B4, 0.8], [NOTES.A4, 1.2],
    [NOTES.F5, 0.4], [NOTES.F5, 0.4], [NOTES.E5, 0.8], [NOTES.C5, 0.8], [NOTES.D5, 0.8], [NOTES.C5, 1.2]
  ]

  // Generate audio for each note and concatenate
  let totalLength = 0
  const tones = melody.map(([freq, dur]) => {
    const tone = generateTone(freq, dur, 0.3)
    totalLength += tone.length
    return tone
  })

  // Concatenate all tones
  const audio = new Float32Array(totalLength)
  let offset = 0
  for (const tone of tones) {
    audio.set(tone, offset)
    offset += tone.length
  }
  return audio
}

function playAudio(audioData) {
  const exe = process.platform === 'win32' ? 'play_buffer.exe' : './play_buffer.exe'
  if (!fs.existsSync(exe)) {
    console.log('play_buffer.exe not found - build it first')
    return
  }
  console.log(`Generated ${audioData.length} samples (${(audioData.length / 44100).toFixed(2)} seconds)`)
  const player = spawn(exe, [], { stdio: ['pipe', 'inherit', 'inherit'] })
  player.on('error', (err) => {
    console.log('Failed to start play_buffer:', err.message)
  })
  player.on('close', (code) => {
    console.log(`play_buffer process exited with code ${code}`)
  })
  player.stdin.on('error', (err) => {
    console.log('Stdin error:', err.message)
  })
  player.stdin.on('close', () => {
    console.log('Stdin closed')
  })
  try {
    const buffer = Buffer.from(new Uint8Array(audioData.buffer, audioData.byteOffset, audioData.byteLength))
    console.log(`Sending ${buffer.length} bytes to play_buffer`)
    player.stdin.write(buffer)
    player.stdin.end()
    console.log('Data written and stdin closed')
  } catch (err) {
    console.log('Error writing audio data:', err.message)
  }
}

// Generate and play Happy Birthday
const melody = generateMelody()
playAudio(melody)
