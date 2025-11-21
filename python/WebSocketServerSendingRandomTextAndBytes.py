import asyncio
import websockets
import random
import string

async def handle_client(websocket):
    """Handle incoming WebSocket connections"""
    print(f"Client connected from {websocket.remote_address}")
    
    # Create task to send random data
    send_task = asyncio.create_task(send_random_data(websocket))
    
    try:
        async for message in websocket:
            if isinstance(message, bytes):
                print(f"Received bytes: {message.hex()} ({len(message)} bytes)")
            else:
                print(f"Received text: {message}")
    except websockets.exceptions.ConnectionClosed:
        print(f"Client disconnected")
    finally:    
        send_task.cancel()
        try:
            await send_task
        except asyncio.CancelledError:
            pass

async def send_random_data(websocket):
    """Send random bytes and text every second"""
    try:
        while True:
            # Send random bytes (1-16 bytes)
            random_bytes = bytes([random.randint(0, 255) for _ in range(random.randint(1, 16))])
            await websocket.send(random_bytes)
            print(f"Sent bytes: {random_bytes.hex()} ({len(random_bytes)} bytes)")
            
            # Send random text
            random_text = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(5, 20)))
            await websocket.send(random_text)
            print(f"Sent text: {random_text}")
            

            # Send a 16-byte random value
            random_16 = bytes([random.randint(0, 255) for _ in range(16)])
            await websocket.send(random_16)
            print(f"Sent 16-byte value: {random_16.hex()} ({len(random_16)} bytes)")

            await asyncio.sleep(1)
    except asyncio.CancelledError:
        pass

async def main():
    """Start the WebSocket server"""
    server = await websockets.serve(handle_client, "localhost", 4513)
    print("WebSocket server started on ws://localhost:4513")
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())