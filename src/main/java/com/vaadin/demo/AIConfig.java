package com.vaadin.demo;

import com.vaadin.demo.config.AIDocsProperties;
import dev.langchain4j.data.document.loader.FileSystemDocumentLoader;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.memory.chat.ChatMemoryProvider;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.ollama.OllamaEmbeddingModel;
import dev.langchain4j.model.ollama.OllamaStreamingChatModel;
import dev.langchain4j.rag.content.retriever.ContentRetriever;
import dev.langchain4j.rag.content.retriever.EmbeddingStoreContentRetriever;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.EmbeddingStoreIngestor;
import dev.langchain4j.store.embedding.qdrant.QdrantEmbeddingStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties({AIDocsProperties.class})
public class AIConfig {

    private static final Logger log = LoggerFactory.getLogger(AIConfig.class);
    private final AIDocsProperties aiDocsProperties;

    @Autowired
    public AIConfig(AIDocsProperties aiDocsProperties) {
        this.aiDocsProperties = aiDocsProperties;
    }

    /**
     * Provides an {@link EmbeddingStore} for managing text segments, backed by Qdrant vector database.
     * Qdrant is specifically designed for vector similarity search and provides excellent performance
     * for embedding storage and retrieval operations.
     *
     * @return a configured Qdrant embedding store for text segments
     */
    @Bean
    public EmbeddingStore<TextSegment> embeddingStore() {
        return QdrantEmbeddingStore.builder()
                .host("qdrant-service")  // Kubernetes service name
                .port(6334)              // Qdrant gRPC port (6333 is HTTP, 6334 is gRPC)
                .collectionName("documents")
                .build();
    }

    /**
     * Provides an {@link EmbeddingModel} that can be used to compute embeddings for text segments.
     * The model is configured using the base URL and model name specified in the
     * {@link AIDocsProperties} for the OpenAI provider.
     *
     * @return an embedding model for computing embeddings for text segments
     */
    @Bean
    public EmbeddingModel embeddingModel() {
        return OllamaEmbeddingModel.builder()
                .baseUrl(aiDocsProperties.getLangchain4j().getOpenAi().getBaseUrl())
                .modelName(aiDocsProperties.getLangchain4j().getOpenAi().getEmbeddingModelName())
                .build();
    }


    /**
     * An {@link ApplicationRunner} that imports documents from the specified location to the MongoDB store.
     * The runner is configured to connect to a MongoDB instance using the provided {@link MongoClient},
     * and uses database and collection names specified in the {@link MongoDbProperties}.
     * An index is created on the collection for efficient querying.
     * The runner also configures an {@link EmbeddingModel} using the base URL and model name specified in the
     * {@link AIDocsProperties} for the OpenAI provider.
     * The documents are loaded from the specified location using a {@link FileSystemDocumentLoader}.
     * The documents are then ingested into the store using an {@link EmbeddingStoreIngestor}.
     * The runner logs the number of documents imported to the store.
     *
     * @param embeddingStore the MongoDB store to store the documents
     * @param embeddingModel the embedding model to use for computing embeddings for the documents
     * @return an application runner that imports documents to the store
     */
    @Bean
    public ApplicationRunner docImporter(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        return args -> {
            var docsLocation = aiDocsProperties.getLocation();
            if (docsLocation == null || docsLocation.isEmpty()) {
                log.error("No document location specified, configure 'ai.docs.location'");
                return;
            }

            log.info("Importing documents from {}", docsLocation);
            var docs = FileSystemDocumentLoader.loadDocuments(docsLocation);

            EmbeddingStoreIngestor.builder()
                    .embeddingModel(embeddingModel)
                    .embeddingStore(embeddingStore)
                    .build()
                    .ingest(docs);

            var response = embeddingModel.embed("test string");
            log.info("Embedding dimension: {}", response.content().dimension());
            log.info("Imported {} documents", docs.size());
        };
    }

    /**
     * Provides a {@link StreamingChatLanguageModel} configured with the base URL and model name
     * specified in the application's AI documentation properties.
     *
     * @return a streaming chat language model
     */
    @Bean
    public StreamingChatLanguageModel streamingChatLanguageModel() {
        return OllamaStreamingChatModel.builder()
                .baseUrl(aiDocsProperties.getLangchain4j().getOpenAi().getBaseUrl())
                .modelName(aiDocsProperties.getLangchain4j().getOpenAi().getModelName())
                .build();
    }

    /**
     * Returns a {@link ContentRetriever} that retrieves content from the provided
     * {@link EmbeddingStore} using the provided {@link EmbeddingModel}.
     *
     * @param embeddingStore the embedding store to retrieve content from
     * @param embeddingModel the embedding model to use for retrieving content
     * @return a content retriever
     */
    @Bean
    public ContentRetriever contentRetriever(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        return EmbeddingStoreContentRetriever.builder()
                .embeddingStore(embeddingStore)
                .embeddingModel(embeddingModel)
                .build();
    }

    /**
     * Returns a {@link ChatMemoryProvider} that provides a {@link MessageWindowChatMemory} with a maximum of 30 messages.
     * This memory provider is used to store the chat history of each chat.
     *
     * @return a chat memory provider
     */
    @Bean
    public ChatMemoryProvider chatMemoryProvider() {
        return chatId -> MessageWindowChatMemory.withMaxMessages(30);
    }

}
