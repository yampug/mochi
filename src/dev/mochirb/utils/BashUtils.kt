package dev.mochirb.utils

import java.io.BufferedReader
import java.io.InputStreamReader


class BashUtils {
    fun bash(command: String?): String {
        val output = StringBuilder()

        println("Command: $command")
        try {
            val processBuilder = ProcessBuilder("/bin/bash", "-c", command)
            val process = processBuilder.start()

            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            while ((reader.readLine().also { line = it }) != null) {
                output.append(line).append("\n")
            }

            val errorReader = BufferedReader(InputStreamReader(process.errorStream))
            var errorLine: String?
            while ((errorReader.readLine().also { errorLine = it }) != null) {
                output.append(errorLine).append("\n")
            }
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                throw RuntimeException("Command failed with exit code: $exitCode")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return output.toString()
    }
}
