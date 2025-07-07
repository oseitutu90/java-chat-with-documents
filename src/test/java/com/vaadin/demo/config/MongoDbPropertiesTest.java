import com.vaadin.demo.config.MongoDbProperties;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class MongoDbPropertiesTest {
    @Test
    void gettersAndSettersWork() {
        MongoDbProperties props = new MongoDbProperties();
        props.setUri("uri");
        props.setDatabase("db");
        props.setCollection("col");
        props.setIndexName("idx");

        assertEquals("uri", props.getUri());
        assertEquals("db", props.getDatabase());
        assertEquals("col", props.getCollection());
        assertEquals("idx", props.getIndexName());
    }
}
