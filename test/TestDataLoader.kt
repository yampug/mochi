package app.acrylic

import org.apache.commons.io.FileUtils.readFileToByteArray
import java.io.File

class TestDataLoader {

    companion object {

        fun loadData(relativePath: String): ByteArray {
            return readFileToByteArray(File("./test/data/$relativePath"))
        }

        fun loadDataString(relativePath: String): String {
            return String(loadData(relativePath))
        }
    }
}