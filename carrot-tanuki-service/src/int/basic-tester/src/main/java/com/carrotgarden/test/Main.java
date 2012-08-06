/**
 * Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
 *
 * All rights reserved. Licensed under the OSI BSD License.
 *
 * http://www.opensource.org/licenses/bsd-license.php
 */
package com.carrotgarden.test;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Main {

	private final static Logger log = LoggerFactory.getLogger(Main.class);

	public static void main(final String... args) throws Exception {

		log.debug("init");

		final File serviceDir = new File(System.getProperty("tester.service"));

		log.debug("serviceDir : {}", serviceDir);

		final File propsFile = new File(serviceDir, "distribution.properties");

		final Properties distroProps = new Properties();
		distroProps.load(new FileInputStream(propsFile));

		final File appDir = new File(serviceDir,
				distroProps.getProperty("archive-folder"));

		log.debug("appDir : {}", appDir);

		try {

			final ProcessRunner runStart = new ProcessRunner(appDir,
					"nix-start.sh");

			runStart.exec();

			Thread.sleep(3 * 1000);

		} finally {

			{

				final File magicFile = new File(appDir, "magic-file");

				boolean isFound = false;

				for (int k = 0; k < 10; k++) {

					if (magicFile.exists()) {
						isFound = true;
						break;
					} else {
						Thread.sleep(1 * 1000);
					}

				}

				if (isFound) {
					log.debug("file found : {}", magicFile);
				} else {
					throw new Exception("can not find file: "
							+ magicFile.getAbsolutePath());
				}

			}

			final ProcessRunner runStop = new ProcessRunner(appDir,
					"nix-stop.sh");

			runStop.exec();

			Thread.sleep(3 * 1000);

		}

		log.debug("done");

	}

}
