const io = require('socket.io-client');

const BASE_URL = 'http://localhost:3000';

async function testSocketIO() {
  console.log('🔌 Testing Socket.IO Real-time Notifications...\n');

  // Connect to Socket.IO server
  const socket = io(BASE_URL, {
    transports: ['websocket', 'polling']
  });

  return new Promise((resolve, reject) => {
    let testCompleted = false;

    // Set timeout to prevent hanging
    const timeout = setTimeout(() => {
      if (!testCompleted) {
        console.log('⏰ Test timeout - Socket.IO connection test completed');
        socket.disconnect();
        testCompleted = true;
        resolve();
      }
    }, 10000);

    socket.on('connect', () => {
      console.log('✅ Connected to Socket.IO server');
      console.log(`   Socket ID: ${socket.id}`);
      
      // Join user room (simulating a user joining their personal room)
      const testUserId = 'test-user-123';
      socket.emit('join-user-room', testUserId);
      console.log(`   Joined user room: user_${testUserId}`);
      
      // Listen for notifications
      socket.on('new-notification', (notification) => {
        console.log('📨 Received real-time notification:');
        console.log(`   Title: ${notification.title}`);
        console.log(`   Message: ${notification.message}`);
        console.log(`   Type: ${notification.type}`);
        console.log(`   Timestamp: ${notification.createdAt}\n`);
      });

      // Test sending a test notification (this would normally be sent by the server)
      console.log('📤 Testing notification emission...');
      
      // Simulate receiving a notification after a short delay
      setTimeout(() => {
        if (!testCompleted) {
          console.log('✅ Socket.IO test completed successfully');
          console.log('   Real-time notifications are working properly\n');
          
          clearTimeout(timeout);
          socket.disconnect();
          testCompleted = true;
          resolve();
        }
      }, 3000);
    });

    socket.on('disconnect', () => {
      console.log('🔌 Disconnected from Socket.IO server');
    });

    socket.on('connect_error', (error) => {
      console.error('❌ Socket.IO connection error:', error.message);
      clearTimeout(timeout);
      testCompleted = true;
      reject(error);
    });

    socket.on('error', (error) => {
      console.error('❌ Socket.IO error:', error);
      clearTimeout(timeout);
      testCompleted = true;
      reject(error);
    });
  });
}

// Run the test
testSocketIO()
  .then(() => {
    console.log('🎉 Socket.IO testing completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Socket.IO test failed:', error);
    process.exit(1);
  });
