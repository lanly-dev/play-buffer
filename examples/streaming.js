const { spawn } = require('child_process')
const path = require('path')
const fs = require('fs')

const sampleRate = 44100
const exe = process.platform === 'win32'
  ? path.join(__dirname, 'play_buffer.exe')
  : path.join(__dirname, '..', 'play_buffer')

// Generator producing a sine tone at a given frequency
function* toneGenerator(freq = 440, amp = 0.3, chunkSize = 2048) {
  let t = 0
  const dt = 1 / sampleRate
  while (true) {
    const chunk = new Float32Array(chunkSize)
    for (let i = 0; i < chunkSize; i++) {
      chunk[i] = amp * Math.sin(2 * Math.PI * freq * t)
      t += dt
    }
    yield Buffer.from(new Uint8Array(chunk.buffer))
  }
}

function main() {
  const gen = toneGenerator(440, 0.3, 2048)
  if (!fs.existsSync(exe)) {
    console.error(`Player not found at ${exe} - build it first or download the latest binary`)
    process.exit(1)
  }
  // Choose streaming mode via command line argument: 'blocking' or 'callback'
  const mode = process.argv[2] === 'blocking' ? '--stream-blocking' : '--stream-callback'
  const child = spawn(exe, [mode], { stdio: ['pipe', 'inherit', 'inherit'] })

  child.on('error', (e) => console.error('Failed to start play_buffer:', e.message))
  child.on('close', (code) => console.log('play_buffer exited with code', code))

  // Send ~5 seconds of audio then end
  let sent = 0
  const targetSamples = sampleRate * 5
  const chunkSamples = 2048

  function pump() {
    while (sent < targetSamples) {
      const buf = gen.next().value
      const ok = child.stdin.write(buf)
      sent += chunkSamples
      if (!ok) {
        child.stdin.once('drain', pump)
        return
      }
    }
    child.stdin.end()
  }

  pump()
}

main()
