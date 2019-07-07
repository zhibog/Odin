package utf16

REPLACEMENT_CHAR :: '\ufffd';
MAX_RUNE         :: '\U0010ffff';

_surr1           :: 0xd800;
_surr2           :: 0xdc00;
_surr3           :: 0xe000;
_surr_self       :: 0x10000;


is_surrogate :: proc(r: rune) -> bool {
	return _surr1 <= r && r < _surr3;
}

decode_surrogate_pair :: proc(r1, r2: rune) -> rune {
	if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
		return (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self;
	}
	return REPLACEMENT_CHAR;
}


encode_surrogate_pair :: proc(r: rune) -> (r1, r2: rune) {
	if r < _surr_self || r > MAX_RUNE {
		return REPLACEMENT_CHAR, REPLACEMENT_CHAR;
	}
	r -= _surr_self;
	return _surr1 + (r>>10)&0x3ff, _surr2 + r&0x3ff;
}

encode :: proc(d: []u16, s: []rune) -> int {
	n, m := 0, len(d);
	loop: for r in s {
		switch r {
		case 0..<_surr1, _surr3 ..< _surr_self:
			if m+1 < n do break loop;
			d[n] = u16(r);
			n += 1;

		case _surr_self .. MAX_RUNE:
			if m+2 < n do break loop;
			r1, r2 := encode_surrogate_pair(r);
			d[n]    = u16(r1);
			d[n+1]  = u16(r2);
			n += 2;

		case:
			if m+1 < n do break loop;
			d[n] = u16(REPLACEMENT_CHAR);
			n += 1;
		}
	}
	return n;
}


encode_string :: proc(d: []u16, s: string) -> int {
	n, m := 0, len(d);
	loop: for r in s {
		switch r {
		case 0..<_surr1, _surr3 ..< _surr_self:
			if m+1 < n do break loop;
			d[n] = u16(r);
			n += 1;

		case _surr_self .. MAX_RUNE:
			if m+2 < n do break loop;
			r1, r2 := encode_surrogate_pair(r);
			d[n]    = u16(r1);
			d[n+1]  = u16(r2);
			n += 2;

		case:
			if m+1 < n do break loop;
			d[n] = u16(REPLACEMENT_CHAR);
			n += 1;
		}
	}
	return n;
}

decode :: proc(s: []u16) -> []rune {
	a := make([]rune, len(s));
	n := 0;
	for i := 0; i < len(s); i += 1 {
		r := s[i];
		switch {
		case r < _surr1, _surr3 <= r:
			a[n] = rune(r);
		case _surr1 <= r && r < _surr2 && i+1 < len(s) && _surr2 <= s[i+1] && s[i+1] < _surr3:
			a[n] += decode_surrogate_pair(rune(r), rune(s[i+1]));
			i += 1;
		case:
			a[n] = REPLACEMENT_CHAR;
		}
		n += 1;
	}
	return a[:n];
}


decode_string :: proc(s: []u16) -> string {
	// NOTE(bill): This is a copy from package utf8, mainly to reduce the need for utf16 to import utf8
	encode_rune :: proc(r: rune) -> ([4]u8, int) {
		buf: [4]u8;
		i := u32(r);
		mask :: u8(0x3f);
		if i <= 1<<7-1 {
			buf[0] = u8(r);
			return buf, 1;
		}
		if i <= 1<<11-1 {
			buf[0] = 0xc0 | u8(r>>6);
			buf[1] = 0x80 | u8(r) & mask;
			return buf, 2;
		}

		// Invalid or Surrogate range
		if i > 0x0010ffff ||
		   (0xd800 <= i && i <= 0xdfff) {
			r = 0xfffd;
		}

		if i <= 1<<16-1 {
			buf[0] = 0xe0 | u8(r>>12);
			buf[1] = 0x80 | u8(r>>6) & mask;
			buf[2] = 0x80 | u8(r)    & mask;
			return buf, 3;
		}

		buf[0] = 0xf0 | u8(r>>18);
		buf[1] = 0x80 | u8(r>>12) & mask;
		buf[2] = 0x80 | u8(r>>6)  & mask;
		buf[3] = 0x80 | u8(r)     & mask;
		return buf, 4;
	}
	length := 0;
	{
		for i := 0; i < len(s); i += 1 {
			r := s[i];
			switch {
			case r < _surr1, _surr3 <= r:
				b, l := encode_rune(rune(r));
				length += l;
			case _surr1 <= r && r < _surr2 && i+1 < len(s) && _surr2 <= s[i+1] && s[i+1] < _surr3:
				c := decode_surrogate_pair(rune(r), rune(s[i+1]));
				i += 1;
				b, l := encode_rune(c);
				length += l;
			case:
				b, l := encode_rune(rune(r));
				length += l;
			}
		}
	}

	a := make([]byte, length);
	n := 0;
	for i := 0; i < len(s); i += 1 {
		r := s[i];
		switch {
		case r < _surr1, _surr3 <= r:
			b, l := encode_rune(rune(r));
			copy(a[n:], b[:l]);
			n += l;
		case _surr1 <= r && r < _surr2 && i+1 < len(s) && _surr2 <= s[i+1] && s[i+1] < _surr3:
			c := decode_surrogate_pair(rune(r), rune(s[i+1]));
			i += 1;
			b, l := encode_rune(c);
			copy(a[n:], b[:l]);
			n += l;
		case:
			b, l := encode_rune(rune(r));
			copy(a[n:], b[:l]);
			n += l;
		}
	}
	return string(a[:n]);
}
