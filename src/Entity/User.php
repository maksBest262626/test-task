<?php

namespace App\Entity;

use App\Entity\Raw\BaseEntity;
use App\Repository\UserRepository;
use App\ValueObject\Email;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Security\Core\User\UserInterface;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
#[UniqueEntity(fields: ['email'], message: 'There is already an account with this email')]
class User extends BaseEntity implements UserInterface
{
    private const PATTERN_USER_ID = 'U%d';

    private const PATTERN_WAREHOUSE_USER_ID = 'DA%d';

    #[ORM\Column(length: 180, unique: true, nullable: false)]
    private string $email;

    #[ORM\Column(nullable: false)]
    private array $roles;

    #[ORM\Column(length: 60, nullable: true)]
    private ?string $firstName = null;

    #[ORM\Column(length: 60, nullable: true)]
    private ?string $lastName = null;

    #[ORM\Column(length: 2, nullable: true)]
    private ?string $locale = null;

    /**
     * @var Collection<int, Application>
     */
    #[ORM\OneToMany(mappedBy: 'user', targetEntity: Application::class, cascade: ['persist', 'remove'], orphanRemoval: true)]
    private Collection $applications;

    public function __construct()
    {
        $this->applications = new ArrayCollection();
    }

    public function getEmail(): string
    {
        return Email::createFromString($this->email)->value();
    }

    public function setEmail(string $email): self
    {
        $this->email = Email::createFromString($email)->value();

        return $this;
    }

    /** @see UserInterface */
    public function getUserIdentifier(): string
    {
        return $this->getEmail();
    }

    public function getWrappedId(): string
    {
        return sprintf(self::PATTERN_USER_ID, $this->getId());
    }

    public function getWrappedUserIdForWarehouse(): string
    {
        return sprintf(self::PATTERN_WAREHOUSE_USER_ID, $this->getId());
    }

    /** @see UserInterface */
    public function getRoles(): array
    {
        $roles = $this->roles;
        // guarantee every user at least has ROLE_USER
        $roles[] = 'ROLE_USER';

        return array_unique($roles);
    }

    public function setRoles(array $roles): self
    {
        $this->roles = $roles;

        return $this;
    }

    /** @see UserInterface */
    public function eraseCredentials(): void
    {
        // If you store any temporary, sensitive data on the user, clear it here
        // $this->plainPassword = null;
    }

    public function getFirstName(): ?string
    {
        return $this->firstName;
    }

    public function setFirstName(string $firstName): self
    {
        $this->firstName = $firstName;

        return $this;
    }

    public function getLastName(): ?string
    {
        return $this->lastName;
    }

    public function setLastName(string $lastName): self
    {
        $this->lastName = $lastName;

        return $this;
    }


    public function getFullName(): string
    {
        $name = array_filter([$this->getFirstName(), $this->getLastName()]);
        // TODO how about declinations? may be using VO is better
        return implode(' ', $name);
    }

    public function getLocale(): ?string
    {
        return $this->locale;
    }

    public function setLocale(string $locale): void
    {
        $this->locale = $locale;
    }

    /**
     * @return Collection<int, Application>
     */
    public function getApplications(): Collection
    {
        return $this->applications;
    }

    public function addApplication(Application $application): static
    {
        if (!$this->applications->contains($application)) {
            $this->applications->add($application);
            $application->setUserId($this);
        }

        return $this;
    }

    public function removeApplication(Application $application): static
    {
        if ($this->applications->removeElement($application)) {
            // set the owning side to null (unless already changed)
            if ($application->getUserId() === $this) {
                $application->setUserId(null);
            }
        }

        return $this;
    }
}
