let currentPort = 50000 + Math.floor(Math.random() * 5000);

export function TestPortNumber(): number {
    currentPort++;
    return currentPort;
}