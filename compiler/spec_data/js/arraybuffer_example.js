// ArrayBuffer and TypedArray example
const buffer = new ArrayBuffer(16);
const view = new Uint8Array(buffer);

view[0] = 255;
view[1] = 128;
view[2] = 64;
view[3] = 32;

view.length;
