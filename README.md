## List of Changes

### `midi_to_art.v`
- Changed to process the entire MIDI output.
- **Note:** Make sure to set the USB port to the one the FPGA is connected to.

---

### `midi_interpreter.v`
- Modified the MIDI interpreter to output a phase increment instead of a frequency value.
- Precomputed phase increments for each MIDI note (calculating in real time using the system clock caused timing issues).

---

### `midi_freq_rom.v`
- Now outputs the phase increment corresponding to each note's frequency, using the phase increment formula, instead of the frequency itself.
- **Note:** Consider renaming this file to better reflect its content.

---

### `I2S.v`
- Major rewrite of this module.
- Default divisor is set to 512; thus, 25MHz / 512 ≈ 48.8kHz sampling rate.
- Assumed all input values are 32 bits wide, even though there are only 16 actual data bits.
- Added a 1-cycle wait before transmitting the MSB.
- FSM logic:
    - Wait 1 cycle before MSB.
    - Transmit the data bits.
    - Add burn cycles to complete 32 bits.
    - Repeat for the other channel.
    - Used a finite state machine (FSM) to encapsulate the logic.

---

## TODO

- [ ] Sine Wave Form
- [ ] Square Wave
- [ ] Triangular Wave
- [ ] Waveform selector
- [ ] FIX: Make note actually turn off after being released
- [ ] Add multi-note functionality / Chord Generator
- [ ] Add button functionality to select between waveforms


## TODO

- [ ] Sine Wave Form
- [ ] Square Wave
- [ ] Triangular Wave
- [ ] Waveform selector
- [ ] FIX: make note actually turn off after being released
- [ ] Add multi note functionality/Chord Generator
- [ ] Add button functionality to select between waveforms

