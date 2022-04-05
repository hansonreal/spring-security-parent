package com.github;

import org.springframework.security.authentication.dao.SaltSource;
import org.springframework.security.core.userdetails.UserDetails;

public class MySaltSource implements SaltSource {
    @Override
    public Object getSalt(UserDetails user) {
        return null;
    }
}
