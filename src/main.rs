use rust_bert::pipelines::text_generation::{TextGenerationConfig, TextGenerationModel};
use rust_bert::resources::LocalResource;
use rust_bert::resources::Resource::Local;
use std::io::stdin;
use std::path::PathBuf;

fn main() {
    let model_resource = Local(LocalResource {
        local_path: PathBuf::from("rust_model.ot"),
    });
    let config_resource = Local(LocalResource {
        local_path: PathBuf::from("config.json"),
    });
    let vocab_resource = Local(LocalResource {
        local_path: PathBuf::from("vocab.json"),
    });
    let merges_resource = Local(LocalResource {
        local_path: PathBuf::from("merges.txt"),
    });

    let generate_config = TextGenerationConfig {
        model_resource,
        config_resource,
        vocab_resource,
        merges_resource,
        max_length: 20,
        num_beams: 3,
        ..Default::default()
    };

    let model = TextGenerationModel::new(generate_config).unwrap();
    loop {
        let mut buf = String::new();
        stdin().read_line(&mut buf).ok();
        let input = buf.trim();
        let results = model.generate(&[input], None);

        for result in results {
            println!("「{:?}」", result);
        }
        println!("\n");
    }
}
