const {SerialPort} = require('serialport');

const tangnano = new SerialPort({
    path: 'COM13',
    baudRate: 115200,
});
var msg = [];
msg = "abc"; //ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
console.log('Gerar um hash sha256 de "'+msg+'"');
for (i = 0; i<msg.length; i++)
    tangnano.write(Buffer.from(msg[i]));

tangnano.on('data', function (data) {
    console.log('Data In Text:', data.toString());
    console.log('Data In Hex:', data.toString('hex'));

    const binary = data.toString().split('').map((byte) => {
        return byte.charCodeAt(0).toString(2).padStart(8, '0');
    });
    console.log('Data In Binary: ', binary.join(' '));
    console.log('\n');
});
