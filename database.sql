USE `essentialmode`;

CREATE TABLE `invest` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `amount` float NOT NULL,
  `rate` float NOT NULL,
  `job` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sold` datetime DEFAULT NULL,
  `soldAmount` float DEFAULT NULL,
  `totalInvestment` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=677 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

ALTER TABLE `invest`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `invest`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;COMMIT;


CREATE TABLE `companies` (
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `price` float DEFAULT NULL,
  `rate` float DEFAULT '0',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

INSERT INTO `companies` (`name`, `label`, `price`, `rate`) VALUES
('24/7', 'TNYFVN', NULL, 'stale'),
('Ammu-Nation', 'AMNA', NULL, 'stale'),
('Augury Insurance', 'AUGIN', NULL, 'stale'),
('Downtown Cab Co.', 'DCC', NULL, 'stale'),
('ECola', 'ECLA', NULL, 'stale'),
('Fleeca', 'FLCA', NULL, 'stale'),
('Globe Oil', 'GLBO', NULL, 'stale'),
('GoPostal', 'GPSTL', NULL, 'stale'),
('Lifeinvader', 'LIVDR', NULL, 'stale'),
('Los Santos Air', 'LSA', NULL, 'stale'),
('Los Santos Customs', 'LSC', NULL, 'stale'),
('Los Santos Transit', 'LST', NULL, 'stale'),
('Maze Bank', 'MBANK', NULL, 'stale'),
('Post OP', 'PSTP', NULL, 'stale'),
('RON', 'RON', NULL, 'stale'),
('Up-n-Atom Burger', 'UNAB', NULL, 'stale'),
('Weazel', 'NEWS', NULL, 'stale');

ALTER TABLE `companies`
  ADD PRIMARY KEY (`name`);
COMMIT;