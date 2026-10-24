"""Generate independent SHA-256 oracle values using Python hashlib."""
from pathlib import Path
import hashlib,json,random
root=Path(__file__).resolve().parents[1]
rng=random.Random(256)
messages=[b'abc',b'abc',b'abb',b'',b'hello',b'DICD CP!',b'a'*55,b'\x00']
messages += [bytes(rng.randrange(256) for _ in range(n)) for n in range(56)]
lines=[]
for msg in messages:
    lines.append(f'{len(msg):02x}'+msg.ljust(55,b'\x00').hex()+hashlib.sha256(msg).hexdigest())
(root/'sim'/'test_vectors.mem').write_text('\n'.join(lines)+'\n')
a=hashlib.sha256(b'abc').digest();b=hashlib.sha256(b'abb').digest()
info={'vector_count':len(messages),'abc':a.hex(),'abb':b.hex(),
      'changed_input_bits':1,'changed_digest_bits':sum((x^y).bit_count() for x,y in zip(a,b))}
(root/'evidence'/'reference_hashes.json').write_text(json.dumps(info,indent=2)+'\n')
print(json.dumps(info))
