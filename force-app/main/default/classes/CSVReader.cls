public with sharing class CSVReader implements Iterable<List<String>>, Iterator<List<String>> {

	private final static String COMMA = ',';
	private final static String CR = '\r';
	private final static String LF = '\n';
	private final static String CRLF = '\r\n';
	private final static String QUOTE = '"';
	private final static String DOUBLE_QUOTE = '""';

	private String csvString;
	private Integer csvStringLength;
	private Integer position = 0;
	private Iterator<List<String>> it;

	public CSVReader(String csvString) {
		this.csvString = convertLineEndings(csvString.trim());
		this.csvStringLength = csvString.length();
		this.it = iterator();
	}

	public static List<List<String>> read(String csvString, Integer size, Integer offset) {
		List<List<String>> res = new List<List<String>>();
		CSVReader reader = new CSVReader(csvString);

        Integer rowCount = 0;
        if (offset == null) {
            offset = 0;
        }

		while (reader.it.hasNext() && res.size() < size) {
            List<String> row = reader.it.next();
            if (rowCount >= offset) {
                res.add(row);
            }
            rowCount++;
		}

		return res;
	}

	private static String convertLineEndings(String str) {
		return str.replace(CRLF, LF).replace(CR, LF);
	}

	public Iterator<List<String>> iterator() {
		return this;
	}

	public Boolean hasNext() {
		return position < csvStringLength;
	}

	public List<String> next() {
		List<String> values = new List<String>();
		position = readLine(position, values);
		return values;
	}

	private Integer readLine(Integer position, List<String> values) {
		Integer startPos = position;

		String currentValue;
		Integer cAt, nlAt, foundAt;

		List<String> tmpValues = new List<String>();
		while (position < csvStringLength) {
			cAt = csvString.indexOf(COMMA, position);
			nlAt = csvString.indexOf(LF, position);
			foundAt = Math.min(cAt, nlAt);

			if (foundAt < 0) {
				foundAt = Math.max(cAt, nlAt);
			}
			if (foundAt < 0) {
				currentValue = csvString.substring(startPos);
				position = csvStringLength;
			}
			else {
				currentValue = csvString.substring(startPos, foundAt);
				position = foundAt + 1;
			}

			if (!currentValue.startsWith(QUOTE)) {
				tmpValues.add(currentValue);

				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue == DOUBLE_QUOTE) {
				tmpValues.add('');
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
			else if (currentValue.endsWith(QUOTE)) {
				Integer lastIndex = currentValue.length() - 1;
				currentValue = currentValue.substring(1, lastIndex);

                Integer doubleQuotedQuotesIndex = currentValue.indexOf(DOUBLE_QUOTE);
                if(doubleQuotedQuotesIndex >= 0) {
                    currentValue = currentValue.replace(DOUBLE_QUOTE, QUOTE);
                }

				tmpValues.add(currentValue);
				if (foundAt == nlAt) {
					break;
				}
				startPos = position;
			}
		}
		values.addAll(tmpValues);
		return position;
	}

    public Integer countLineBreaks() {
        Integer countLines = 0;
        for (Integer i=0; i<this.csvString.length(); i++) {
            if (this.csvString.substring(i, i+1) == LF) {
                countLines++;
            }
        }
        if (!this.csvString.endsWith(LF)) {
            countLines++;
        }
        return countLines;
    }

    public List<String> sliceRawLines(Integer size, Integer offset) {
        List<String> output = new List<String>();
        if (size == null || size <= 0) return output;
        if (offset == null || offset < 0) offset = 0;

        Integer lineCount = 0;
        Integer start = 0;

        for (Integer i = 0; i < csvString.length(); i++) {
            if (csvString.substring(i, i+1) == LF) {
                if (lineCount >= offset && output.size() < size) {
                    output.add(csvString.substring(start, i));
                }
                lineCount++;
                start = i + 1;
                if (output.size() == size) break;
            }
        }
        if (output.size() < size && start < csvString.length()) {
            if (lineCount >= offset) output.add(csvString.substring(start));
        }
        return output;
    }

    public JoinResult joinUntilLimit(List<String> lines, Integer maxChars) {
        if (lines == null || lines.isEmpty()) return new JoinResult('', 0);

        List<String> parts = new List<String>();
        Integer used = 0, usedLines = 0;

        for (Integer i = 0; i < lines.size(); i++) {
            String candidate = (i == 0) ? lines[i] : '\n' + lines[i];
            if (used + candidate.length() > maxChars) break;

            parts.add(candidate);
            used += candidate.length();
            usedLines++;
        }

        return new JoinResult(String.join(parts, ''), usedLines);
    }

    public class JoinResult {
        public String payload;
        public Integer linesUsed;
        public JoinResult(String p, Integer n) { payload = p; linesUsed = n; }
    }
}
