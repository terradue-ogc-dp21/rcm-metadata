$graph:

- class: Workflow
 
  id: main

  requirements:
   ScatterFeatureRequirement: {}

  inputs:

    rcm:
      type: Directory[]

  outputs:
    - id: wf_outputs
      outputSource:
        - node_raw/stac
      type: Directory[]

  steps:

    node_raw: 
     
      in: 
        rcm: rcm 

      out: 
        - stac
      
      run:

        class: CommandLineTool

        hints:
          DockerRequirement:
            dockerPull: raw

        baseCommand: [rcm-raw]

        arguments:
        - $( inputs.rcm.path + "/" + inputs.rcm.basename + ".zip")

        inputs: 
          rcm: 
            inputBinding:
            type: Directory
            
        outputs:
          stac:
            outputBinding:
              glob: .
            type: Directory
        requirements:
          EnvVarRequirement:
            envDef:
              PATH: /home/fbrito/work/rcm-metadata:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          InlineJavascriptRequirement: {}  
      scatter: rcm
      scatterMethod: dotproduct

cwlVersion: v1.0