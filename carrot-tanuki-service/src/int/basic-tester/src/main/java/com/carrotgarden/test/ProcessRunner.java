/**
 * Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
 *
 * All rights reserved. Licensed under the OSI BSD License.
 *
 * http://www.opensource.org/licenses/bsd-license.php
 */
package com.carrotgarden.test;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ProcessRunner {

	private final static Logger log = LoggerFactory
			.getLogger(ProcessRunner.class);

	private final File dir;
	private final String cmd;

	public ProcessRunner(final File dir, final String cmd) {
		this.dir = dir;
		this.cmd = cmd;
	}

	private Process process;

	public Process process() {
		return process;
	}

	public void exec() throws Exception {

		final String command = new File(dir, cmd).getAbsolutePath();

		final ProcessBuilder builder = new ProcessBuilder()
				.redirectErrorStream(true).directory(dir).command(command);

		log.debug("{}", cmd);

		process = builder.start();

		final BufferedReader reader = new BufferedReader(new InputStreamReader(
				process.getInputStream()));

		while (true) {

			final String line = reader.readLine();

			if (line == null) {
				break;
			}

			log.debug("{} : {}", cmd, line);

		}

	}

}
