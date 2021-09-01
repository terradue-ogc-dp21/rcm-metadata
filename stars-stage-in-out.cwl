$graph:
- class: Workflow
  label: Stage-in/out (source to local filesystem or source to sink object storages)
  doc: Stage-in/out (source to local filesystem or source to sink object storages)
  id: main
  inputs:
    source-access-key-id:
      doc: Source access-key-id if staging from object storage (optional)
      type: string?
    source-secret-access-key:
      doc: Source secret access key if staging from object storage (optional)
      type: string?
    source-service-url:
      doc: Source region if staging from object storage (optional)
      type: string?
    source-region:
      doc: Source region if staging from object storage (optional)
      type: string?
    sink-access-key-id:
      doc: Sink access key id if staging to object storage (optional)
      type: string?
    sink-secret-access-key:
      doc: Sink secret access key if staging to object storage (optional)
      type: string?
    sink-service-url:
      doc: Sink service URL if staging to object storage (optional)
      type: string?
    sink-region:
      doc: Sink region if staging to object storage (optional)
      type: string?      
    sink-path:
      doc: Sink path if staging to object storage (optional)
      type: string?  
    input-reference:
      doc: A reference to an opensearch catalog
      label: A reference to an opensearch catalog
      type: Directory[]
  outputs:
  - id: wf_outputs_m
    outputSource:
    - node_stage_out/wf_outputs_out
    type:
          type: array
          items:
            type: array
            items: Directory
  requirements:
   ScatterFeatureRequirement: {}
  steps:
    node_stage_in:
      in:
        inp1: input-reference
        source_access_key_id: source-access-key-id
        source_secret_access_key: source-secret-access-key
        source_service_url: source-service-url
        source_region: source-region
      out:
      - results
      run: 
        arguments:
        - copy
        - -rel
        - -r
        - '4'
        - --harvest
        - -o
        - ./
        - valueFrom: ${ return "file://" + inputs.inp1.path + "/item.json"; }
        baseCommand: Stars
        class: CommandLineTool
        hints:
          DockerRequirement:
            dockerPull: terradue/stars-t2:latest
        inputs:
          inp1:
            inputBinding:
            type: Directory
          source_access_key_id:
            type: string?
          source_secret_access_key:
            type: string?
          source_service_url:
            type: string?
          source_region:
            type: string?
        outputs:
          results:
            outputBinding:
              glob: .
            type: Any
        requirements:
          EnvVarRequirement:
            envDef:
              AWS_ACCESS_KEY_ID: $(inputs.source_access_key_id)
              AWS_SECRET_ACCESS_KEY: $(inputs.source_secret_access_key)
              AWS__ServiceURL: $(inputs.source_service_url)
              AWS__Region: $(inputs.source_region)
              AWS__AuthenticationRegion: $(inputs.source_region)
              AWS__SignatureVersion: "2"
              PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          ResourceRequirement: {}    
          InlineJavascriptRequirement: {}
      scatter: inp1
      scatterMethod: dotproduct     
    node_stage_out:
      in:
        sink_access_key_id: sink-access-key-id
        sink_secret_access_key: sink-secret-access-key
        sink_service_url: sink-service-url
        sink_path: sink-path
        sink_region: sink-region
        wf_outputs: 
            source: [node_stage_in/results]
      out:
      - wf_outputs_out
      run:
        arguments:
        - copy
        - -rel
        - -v
        - --harvest
        - -r
        - '4'
        baseCommand: Stars
        class: CommandLineTool
        cwlVersion: v1.0
        doc: Run Stars for staging data
        hints:
          DockerRequirement:
            dockerPull: terradue/stars-t2:latest
        id: stars
        inputs:
          sink_access_key_id:
            type: string?
          sink_secret_access_key:
            type: string?
          sink_service_url:
            type: string?
          sink_region:
            type: string?
          sink_path:
            inputBinding:
              position: 5
              prefix: -o
            type: string?
          wf_outputs:
            inputBinding:
              position: 6
            type: Directory[]
        outputs:
          wf_outputs_out:
            outputBinding:
              glob: .
            type: Directory[]
        requirements:
          EnvVarRequirement:
            envDef:
              AWS_ACCESS_KEY_ID: $(inputs.sink_access_key_id)
              AWS_SECRET_ACCESS_KEY: $(inputs.sink_secret_access_key)
              AWS__ServiceURL: $(inputs.sink_service_url)
              AWS__Region: $(inputs.sink_region)
              AWS__AuthenticationRegion: $(inputs.sink_region)
              AWS__SignatureVersion: "2"
              PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          ResourceRequirement: {}
      scatter: wf_outputs
      scatterMethod: dotproduct
cwlVersion: v1.0