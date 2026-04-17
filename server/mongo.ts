import { connect, connection } from 'mongoose';

import dns from "dns";

dns.setServers(["8.8.8.8", "1.1.1.1"]);

const connectToMongo = async (): Promise<void> => {
  let mongodbURI: string;
  if (process.env.NODE_ENV === 'test') {
    mongodbURI = process.env.MONGODB_TEST_URI as string;
  } else {
    mongodbURI = process.env.MONGODB_URI as string;
  }
  try {
    await connect(mongodbURI);
    console.log(`Connected to MongoDB (db: ${mongodbURI.split('/').pop()})`);
  } catch (ex) {
    console.log("unable to connect: " + ex);
  }
};

const disconnectMongo = async (): Promise<void> => {
  await connection.close();
};

export { connectToMongo, disconnectMongo };
