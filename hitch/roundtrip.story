Reading in YAML, editing it and writing it back out:
  docs: howto/roundtripping
  based on: strictyaml
  description: |
    Loaded YAML can be modified and dumped out again with
    comments preserved using .as_yaml().

    Note that due to some bugs in the library (ruamel.yaml)
    underlying StrictYAML, while the data parsed should
    be precisely the same, the exact syntax (newlines, comment
    locations, etc.) may not be identical.
  given:
    yaml_snippet: |
      # Some comment

      a: â # value comment

      # Another comment
      b:
        x: 4
        y: 5
      c:
      - a: 1
      - b: 2
    setup: |
      from strictyaml import Map, MapPattern, Str, Seq, Int, load
      from ensure import Ensure

      schema = Map({
          "a": Str(),
          "b": Map({"x": Int(), "y": Int()}),
          "c": Seq(MapPattern(Str(), Str())),
      })
  variations:
    Commented:
      steps:
      - Run:
          code: |
            Ensure(load(yaml_snippet, schema).as_yaml()).equals(yaml_snippet)

    Modified with invalid variable:
      steps:
      - Run:
          code: |
            to_modify = load(yaml_snippet, schema)
            to_modify['b']['x'] = 2
            to_modify['c'][0]['a'] = '3'
            to_modify['b']['x'] = 'not an integer'
          raises:
            type: strictyaml.exceptions.YAMLValidationError
            message: |-
              when expecting an integer
                in "None", line 1, column 1:
                  not an integer
                   ^ (line: 1)
              found arbitrary text
                in "None", line 2, column 1:
                  ...
                  ^ (line: 2)
    Modified with float:
      steps:
      - run:
          code: |
            to_modify = load(yaml_snippet, schema)
            to_modify['c'][0]['a'] = "1.0001"
            print(to_modify.as_yaml())
          will output: |-
            # Some comment

            a: â # value comment

            # Another comment
            b:
              x: 4
              y: 5
            c:
            - a: 1.0001
            - b: 2


    Modified with one variable:
      steps:
      - run:
          code: |
            to_modify = load(yaml_snippet, schema)
            to_modify['b']['x'] = 2
            to_modify['c'][0]['a'] = '3'
            print(to_modify.as_yaml())
          will output: |-
            # Some comment

            a: â # value comment

            # Another comment
            b:
              x: 2
              y: 5
            c:
            - a: 3
            - b: 2

    Text across lines:
      steps:
      - run:
          code: |
            to_modify = load(yaml_snippet, schema)

            to_modify['c'][0]['a'] = "text\nacross\nlines"
            print(to_modify.as_yaml())
          will output: |-
            # Some comment

            a: â # value comment

            # Another comment
            b:
              x: 4
              y: 5
            c:
            - a: |-
                text
                across
                lines
            - b: 2
