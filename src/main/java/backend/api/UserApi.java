package backend.api;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import backend.db.entity.UserEntity;
import backend.db.exception.RecordNotFoundException;
import backend.db.service.UserService;


@RestController
@RequestMapping("/api/user")
public class UserApi {
    @Autowired
    UserService service;

    @GetMapping("/all")
    public ResponseEntity<List<UserEntity>> getAllUsers() {
        List<UserEntity> allUsers = service.getAllUsers();
        return new ResponseEntity<>(allUsers, new HttpHeaders(), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserEntity> getUserById(@PathVariable("id") Long id) throws RecordNotFoundException {
        UserEntity user = service.getUserById(id);
        return new ResponseEntity<>(user, new HttpHeaders(), HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<UserEntity> createOrUpdateUser(UserEntity user) throws RecordNotFoundException {
        UserEntity updatedUser = service.createOrUpdateUser(user);
        return new ResponseEntity<>(updatedUser, new HttpHeaders(), HttpStatus.OK);
    }

    @DeleteMapping("/{id}")
    public HttpStatus deleteUserById(@PathVariable("id") Long id) throws RecordNotFoundException {
        service.deleteUserById(id);
        return HttpStatus.FORBIDDEN;
    }
}